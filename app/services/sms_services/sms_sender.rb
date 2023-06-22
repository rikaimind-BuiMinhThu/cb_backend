module SmsServices
  class SmsSender
    require 'uri'
    require 'net/http'

    attr_reader :sms_code, :token, :client_id, :mt_api_endpoint

    def initialize
      @sms_code = Settings.sms.SMS_CODE
      @token = Settings.sms.TOKEN
      @client_id = Settings.sms.CLIENT_ID
      @mt_api_endpoint = Settings.sms.MT_API_ENDPOINT
    end

    def send(message, phoneNumber, clientTag)
      HttpManager.new(
        @mt_api_endpoint,
        {
          "smsCode": @sms_code,
          "token": @token,
          "clientId": @client_id,
          "message": message,
          "phoneNumber": phoneNumber,
          "clientTag": clientTag,
        }
      ).post_request({ 'Content-Type' => 'application/x-www-form-urlencoded' })
    end
  end
end