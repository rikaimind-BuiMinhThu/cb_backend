module FacebookManager
  class InstagramSetting
    include ActiveModel::Model
    attr_reader :fb_AuthResponse, :page_id, :ig_id, :user_id

    FACEBOOK_SDK = Settings.facebook.sdk.url + Settings.facebook.sdk.version

    def initialize(fb_AuthResponse, page_id, ig_id, user_id)
      @fb_AuthResponse = fb_AuthResponse
      @page_id = page_id
      @ig_id = ig_id
      @user_id = user_id
    end

    def connect
      # get long-lived token user
      result = get_request "#{FACEBOOK_SDK}/oauth/access_token?grant_type=fb_exchange_token&client_id=#{Settings.facebook.meta_app.app_id}&client_secret=#{Settings.facebook.meta_app.app_secret}&fb_exchange_token=#{@fb_AuthResponse["accessToken"]}"
      result_json = JSON.parse(result.body)
      return result_json["error"]["message"] if result_json["error"].present?
      long_lived_access_token_user = result_json["access_token"]
      # get long-lived token page
      result = get_request "#{FACEBOOK_SDK}/#{@page_id}?fields=access_token&access_token=#{long_lived_access_token_user}"
      result_json = JSON.parse(result.body)
      return result_json["error"]["message"] if result_json["error"].present?
      page_access_token = result_json["access_token"]
      # create connect to instagram account
      ig_account = InstagramAccount.find_or_create_by(ig_id: @ig_id)
      ig_account.assign_attributes({
        user_id: @user_id,
        page_id: @page_id,
        page_access_token: page_access_token,
        fb_user_id: @fb_AuthResponse["userID"],
      })

      if ig_account.save
        return 1
      else
        return "Connect Instagram error!"
      end
    end

    private

    def get_request url
      puts url
      require 'uri'
      require 'net/http'
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      header = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      request = Net::HTTP::Get.new(uri.request_uri, header)
      response = http.request(request)
    end
  end
end
