require "faraday"
require "faraday/retry"

module Shopify
  class AuthService
    class AuthError < StandardError; end

    def self.fetch_access_token(client)
      new(client).admin_token
    end

    def self.fetch_storefront_token(client)
      new(client).storefront_token
    end

    def self.refresh!(client)
      new(client).refresh_tokens
    end

    def initialize(client)
      @client = client
      @token_record = ShopifyAccessToken.find_or_initialize_by(client_id: client.id)
    end

    def admin_token(force_refresh: false)
      begin
        refresh_tokens if force_refresh || !@token_record.valid_tokens?
      rescue => e
        log_warn "DB refresh failed (#{shop_url}). Error: #{e.message}"
      end

      if @token_record.valid_tokens?
        @token_record.admin_token
      elsif @client.shop_url.blank? || @client.shop_url == Rails.application.secrets.shop_name
        log_info "Using secrets.yml fallback for admin_token (#{shop_url})"
        Rails.application.secrets.access_token
      else
        log_error "No valid token for specific shop: #{shop_url} and refresh failed. Ensure client_id and client_secret are set in the database."
        nil
      end
    end

    def storefront_token(force_refresh: false)
      begin
        refresh_tokens if force_refresh || !@token_record.valid_tokens?
      rescue => e
        log_warn "DB refresh failed for storefront (#{shop_url}). Error: #{e.message}"
      end

      if @token_record.valid_tokens?
        @token_record.storefront_token
      elsif @client.shop_url.blank? || @client.shop_url == Rails.application.secrets.shop_name
        log_info "Using secrets.yml fallback for storefront_token (#{shop_url})"
        Rails.application.secrets.storefront_access_token
      else
        nil
      end
    end

    def self.shopify_logger
      Rails.logger
    end

    def refresh_tokens
      retries = 0
      max_retries = 3

      if @client.client_id.blank? || @client.client_secret.blank?
        log_warn "Missing client_id/client_secret in DB for client_id: #{@client.id} (#{shop_url}). Skipping token refresh. If you want to use the database for token storage, please fill in these fields."
        return
      end

      begin
        resp_admin = perform_admin_request
        
        if resp_admin.success?
          data = JSON.parse(resp_admin.body)
          admin_token = data["access_token"]
          expires_in = data["expires_in"]

          storefront_token = fetch_storefront_token_from_shopify(admin_token)

          if admin_token.blank? || storefront_token.blank?
            raise AuthError, "One or both tokens are missing (Admin: #{admin_token.present?}, Storefront: #{storefront_token.present?})"
          end

          @token_record.admin_token = admin_token
          @token_record.storefront_token = storefront_token
          @token_record.expires_in = expires_in
          @token_record.issued_at = Time.current
          @token_record.expires_at = Time.current + expires_in.to_i.seconds
          
          if @token_record.save!
            action = @token_record.previously_new_record? ? "Created" : "Updated"
            log_info "SUCCESS: #{action} access tokens in DB for client_id: #{@client.id}"
          end
          
          @token_record.reload
        else
          log_error "Admin token request failed. Status: #{resp_admin.status}."
          raise AuthError, "Shopify returned non-success status: #{resp_admin.status}"
        end
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
        log_warn "NETWORK ERROR: #{e.message}"
        if retries < max_retries
          retries += 1
          sleep(retries)
          retry
        end
        log_fatal "Connection failed after #{max_retries} attempts."
        raise AuthError, "Connection failed after #{max_retries} attempts."
      rescue StandardError => e
        if retries < max_retries
          retries += 1
          log_error "LOGIC ERROR (Attempt #{retries}/#{max_retries}): #{e.message}"
          sleep(retries * 0.5)
          retry
        end
        log_fatal "All #{max_retries} retry attempts exhausted. Final Error: #{e.message}"
        raise AuthError, "Failed after #{max_retries} attempts: #{e.message}"
      end
    end

    def shop_url
      @shop_url ||= begin
        url = @client.shop_url.presence || Rails.application.secrets.shop_name
        if url.present? && !url.to_s.include?(".")
          "#{url}.myshopify.com"
        else
          url.to_s
        end
      end
    end

    private

    def log_info(msg);  Rails.logger.info  "[Shopify] #{msg}"; end
    def log_warn(msg);  Rails.logger.warn  "[Shopify] #{msg}"; end
    def log_error(msg); Rails.logger.error "[Shopify] #{msg}"; end
    def log_fatal(msg); Rails.logger.fatal "[Shopify] #{msg}"; end

    def perform_admin_request
      conn = Faraday.new(url: "https://#{shop_url}") do |f|
        f.request :url_encoded
        f.request :retry, max: 2, interval: 0.5, backoff_factor: 2, exceptions: [Faraday::ConnectionFailed, Faraday::TimeoutError]
        f.adapter Faraday.default_adapter
      end

      conn.post('/admin/oauth/access_token') do |req|
        req.options.timeout = 5
        req.options.open_timeout = 2
        req.body = {
          "client_id"     => @client.client_id,
          "client_secret" => @client.client_secret,
          "grant_type"    => "client_credentials"
        }
      end
    end

    def fetch_storefront_token_from_shopify(admin_token)
      session = ShopifyAPI::Auth::Session.new(
        shop: shop_url,
        access_token: admin_token
      )
      client_shopify = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
      query = <<~GQL
        mutation {
          storefrontAccessTokenCreate(input: { title: "Chatbot-Token" }) {
            storefrontAccessToken {
              accessToken
            }
            userErrors {
              field
              message
            }
          }
        }
      GQL
      
      response = client_shopify.query(query: query)
      if response.code == 200
        token = response.body.dig("data", "storefrontAccessTokenCreate", "storefrontAccessToken", "accessToken")
        return token if token.present?
        
        errors = response.body.dig("data", "storefrontAccessTokenCreate", "userErrors")
        log_error "[ShopifyStorefrontToken] UserErrors: #{errors}"
        raise AuthError, "Shopify Storefront error: #{errors.first["message"]}" if errors.any?
        nil
      else
        log_error "[ShopifyStorefrontToken] Failed. Status: #{response.code}"
        raise AuthError, "Storefront token request failed with status #{response.code}"
      end
    end
  end
end