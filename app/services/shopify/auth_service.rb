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

    def admin_token
      begin
        refresh_tokens if !@token_record.valid_tokens?
      rescue => e
        self.class.shopify_logger.warn "[ShopifyAuth] DB refresh failed (#{shop_url}). Using secrets.yml fallback. Error: #{e.message}"
      end

      @token_record.valid_tokens? ? @token_record.admin_token : Rails.application.secrets.access_token
    end

    def storefront_token
      begin
        refresh_tokens if !@token_record.valid_tokens?
      rescue => e
      end

      @token_record.valid_tokens? ? @token_record.storefront_token : Rails.application.secrets.storefront_access_token
    end

    def self.shopify_logger
      @shopify_logger ||= ActiveSupport::Logger.new(Rails.root.join('log', 'shopify.log'))
    end

    def refresh_tokens
      retries = 0
      max_retries = 3

      begin
        resp_admin = perform_admin_request
        
        if resp_admin.success?
          data = JSON.parse(resp_admin.body)
          admin_token = data["access_token"]
          expires_in = data["expires_in"] || 86399 

          storefront_token = fetch_storefront_token_from_shopify(admin_token)

          if admin_token.blank? || storefront_token.blank?
            raise AuthError, "One or both tokens are missing (Admin: #{admin_token.present?}, Storefront: #{storefront_token.present?})"
          end

          @token_record.admin_token = admin_token
          @token_record.storefront_token = storefront_token
          @token_record.expires_in = expires_in
          @token_record.issued_at = Time.current
          @token_record.expires_at = Time.current + expires_in.seconds
          
          if @token_record.save!
            action = @token_record.previously_new_record? ? "Created" : "Updated"
            self.class.shopify_logger.info "[ShopifyAuth] SUCCESS: #{action} access tokens for client_id: #{@client.id}"
          end
          
          @token_record.reload
        else
          self.class.shopify_logger.error "[ShopifyAuth] ERROR: Admin token failed. Status: #{resp_admin.status}"
          raise AuthError, "Shopify returned non-success status: #{resp_admin.status}"
        end
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
        self.class.shopify_logger.warn "[ShopifyAuth] NETWORK ERROR: Connection failed/timed out. Message: #{e.message}"
        if retries < max_retries
          retries += 1
          wait_time = retries * 1
          self.class.shopify_logger.warn "[ShopifyAuth] RETRY: Attempt ##{retries}/#{max_retries}. Waiting #{wait_time}s..."
          sleep(wait_time)
          retry
        end
        self.class.shopify_logger.fatal "[ShopifyAuth] FATAL: Connection failed after #{max_retries} attempts."
        raise AuthError, "FATAL: Connection failed after #{max_retries} attempts."
      rescue StandardError => e
        if retries < max_retries
          retries += 1
          wait_time = retries
          self.class.shopify_logger.error "[ShopifyAuth] LOGIC ERROR: ##{retries}/#{max_retries}. Error: #{e.message}"
          self.class.shopify_logger.warn "[ShopifyAuth] RETRY: Waiting #{wait_time}s..."
          sleep(wait_time)
          retry
        end
        self.class.shopify_logger.fatal "[ShopifyAuth] FATAL FAILURE: All #{max_retries} retry attempts exhausted. Final Error: #{e.message}"
        raise AuthError, "Failed after #{max_retries} attempts: #{e.message}"
      end
    end

    private

    def shop_url
      @client.shop_url.presence || Rails.application.secrets.shop_name
    end

    def perform_admin_request
      conn = Faraday.new(url: "https://#{shop_url}") do |f|
        f.request :url_encoded
        f.request :retry, max: 2, interval: 0.5, backoff_factor: 2, exceptions: [Faraday::ConnectionFailed, Faraday::TimeoutError]
        f.adapter Faraday.default_adapter
      end

      conn.post('/admin/oauth/access_token') do |req|
        req.options.timeout = 10
        req.options.open_timeout = 5
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
        self.class.shopify_logger.error "[ShopifyStorefrontToken] UserErrors: #{errors}"
        raise AuthError, "Shopify Storefront error: #{errors.first["message"]}" if errors.any?
        nil
      else
        self.class.shopify_logger.error "[ShopifyStorefrontToken] Failed. Status: #{response.code}"
        raise AuthError, "Storefront token request failed with status #{response.code}"
      end
    end
  end
end
