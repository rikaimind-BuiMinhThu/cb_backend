module FacebookManager
  class InstagramSetting
    include ActiveModel::Model
    attr_reader :fb_AuthResponse, :page_id, :ig_id, :user_id

    def initialize(fb_AuthResponse, page_id, ig_id, user_id)
      @fb_AuthResponse = fb_AuthResponse
      @page_id = page_id
      @ig_id = ig_id
      @user_id = user_id
    end

    def connect
      user_token_result = exchange_token(@fb_AuthResponse['accessToken'])
      return user_token_result[:error][:message] unless user_token_result[:success]

      page_token_result = fetch_page_token(user_token_result[:data]['access_token'])
      return page_token_result[:error][:message] unless page_token_result[:success]

      page_access_token = page_token_result[:data]['access_token']
      ig_account = InstagramAccount.find_or_create_by(ig_id: @ig_id)
      ig_account.assign_attributes(
        user_id: @user_id,
        page_id: @page_id,
        page_access_token: page_access_token,
        fb_user_id: @fb_AuthResponse['userID']
      )

      if ig_account.save
        subscribe_webhooks(page_access_token)
        return 1
      end

      'Connect Instagram error!'
    end

    private

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

    def subscribe_webhooks(page_access_token)
      GraphApiClient.new(page_access_token).post(
        "#{@page_id}/subscribed_apps",
        {},
        subscribed_fields: 'messages,messaging_postbacks,comments,live_comments'
      )
    end
  end
end
