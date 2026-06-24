module FacebookManager
  class InstagramSetting
    include ActiveModel::Model
    attr_reader :fb_AuthResponse, :page_id, :ig_id, :user_id, :page_access_token

    def initialize(fb_AuthResponse, page_id, ig_id, user_id, page_access_token: nil)
      @fb_AuthResponse = fb_AuthResponse
      @page_id = page_id
      @ig_id = ig_id
      @user_id = user_id
      @page_access_token = page_access_token
    end

    def connect
      page_token_result = resolve_page_access_token
      return page_token_result[:error] unless page_token_result[:success]

      page_token = page_token_result[:token]
      validation_error = validate_instagram_connection(page_token)
      return validation_error if validation_error

      ig_account = InstagramAccount.find_or_create_by(ig_id: @ig_id)
      ig_account.assign_attributes(
        user_id: @user_id,
        page_id: @page_id,
        page_access_token: page_token,
        fb_user_id: fb_auth[:userID]
      )

      return ig_account.errors.full_messages.join(', ') unless ig_account.save

      subscription_error = subscribe_webhooks(page_token)
      return subscription_error if subscription_error

      1
    end

    private

    def fb_auth
      @fb_auth ||= begin
        raw = @fb_AuthResponse
        raw = raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)
        raw.with_indifferent_access
      end
    end

    def resolve_page_access_token
      if @page_access_token.present?
        return { success: true, token: @page_access_token }
      end

      user_token = fb_auth[:accessToken]
      return { success: false, error: 'Missing Facebook access token' } if user_token.blank?

      user_token_result = exchange_token(user_token)
      unless user_token_result[:success]
        return { success: false, error: user_token_result.dig(:error, :message) || 'Token exchange failed' }
      end

      page_token_result = fetch_page_token(user_token_result[:data]['access_token'])
      unless page_token_result[:success]
        return { success: false, error: page_token_result.dig(:error, :message) || 'Failed to fetch page token' }
      end

      { success: true, token: page_token_result[:data]['access_token'] }
    end

    def exchange_token(short_lived_token)
      GraphApiClient.new.get(
        'oauth/access_token',
        grant_type: 'fb_exchange_token',
        client_id: Settings.facebook.meta_app.app_id,
        client_secret: Settings.facebook.meta_app.app_secret,
        fb_exchange_token: short_lived_token
      )
    end

    def fetch_page_token(user_access_token)
      GraphApiClient.new(user_access_token).get("#{@page_id}", fields: 'access_token')
    end

    def validate_instagram_connection(page_access_token)
      profile_result = GraphApiClient.new(page_access_token).get(
        @ig_id.to_s,
        fields: 'id,username'
      )
      return profile_result.dig(:error, :message) unless profile_result[:success]

      media_result = GraphApiClient.new(page_access_token).get(
        "#{@ig_id}/media",
        fields: 'id,media_type',
        limit: 1
      )
      return media_result.dig(:error, :message) unless media_result[:success]

      nil
    end

    def subscribe_webhooks(page_access_token)
      result = GraphApiClient.new(page_access_token).post(
        "#{@page_id}/subscribed_apps",
        {},
        # Page subscribed_apps only accepts Page fields (not Instagram comments/live_comments).
        subscribed_fields: 'messages,messaging_postbacks'
      )
      return nil if result[:success]

      message = result.dig(:error, :message) || 'Webhook subscription failed'
      Rails.logger.warn("[instagram_connect] Webhook subscription failed: #{message}")
      message
    rescue StandardError => e
      Rails.logger.warn("[instagram_connect] Webhook subscription failed: #{e.message}")
      e.message
    end
  end
end
