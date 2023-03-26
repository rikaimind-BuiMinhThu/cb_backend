require File.dirname(__FILE__) + "/../log"
require "uri"
require "net/http"

module Captcha
  class RecaptchaV2
    TWO_CAPTCHA_IN_URL = "http://2captcha.com/in.php?key=:api_key&method=:method&googlekey=:google_key&pageurl=:page_url&json=1"
    TWO_CAPTCHA_RES_URL = "http://2captcha.com/res.php?key=:api_key&action=get&id=:request_id&json=1"

    def initialize(google_key, page_url, log_tab_level)
      @google_key = google_key
      @page_url = page_url
      @log_tab_level = log_tab_level
    end

    def process
      @log_tab_level += 1
      Log.info "RecaptchaV2 start for key: #{@google_key}", @log_tab_level
      response = send_in_request
      request_id = response["request"]

      Log.info "Sleep 15 for waiting recaptcha V2 response", @log_tab_level
      sleep 15

      begin
        try_count = 1
        while try_count <= 10
          response = get_captcha_response(request_id)
          if response != :retry_again
            Log.info "#{try_count}: Sleep more 5 seconds for retry", @log_tab_level
            sleep 5
            try_count += 1
          end

          return response
        end
      rescue e
        Log.error e.message, @log_tab_level
      end

      @log_tab_level -= 1
    end

    def get_captcha_response(request_id)
      Log.info "get_captcha_response for request_id: #{request_id}", @log_tab_level
      @log_tab_level += 1

      uri = URI(TWO_CAPTCHA_RES_URL.gsub(":api_key", api_key)
        .gsub(":request_id", request_id))

      res = Net::HTTP.get_response(uri)
      Log.info res.inspect, @log_tab_level
      if res.is_a?(Net::HTTPSuccess)
        Log.info "get_captcha_response: success", @log_tab_level
        Log.info "response body: #{res.body}", @log_tab_level
        @log_tab_level -= 1
        res = JSON.parse(res.body)

        if res["error_code"] == "CAPCHA_NOT_READY"
          return :retry_again
        end

        return res["request"]
      else
        Log.info "send_in_request: failed"
        @log_tab_level -= 1
        raise "Recaptcha V2 failure #{@google_key}, request_id: #{request_id}"
        return nil
      end

      @log_tab_level -= 1
    end

    def send_in_request
      Log.info "Send in request", @log_tab_level
      @log_tab_level += 1
      uri = URI(TWO_CAPTCHA_IN_URL.gsub(":api_key", api_key)
        .gsub(":method", "userrecaptcha")
        .gsub(":google_key", @google_key)
        .gsub(":page_url", CGI.escape(@page_url)))

      res = Net::HTTP.get_response(uri)
      if res.is_a?(Net::HTTPSuccess)
        Log.info "send_in_request: success", @log_tab_level
        Log.info "response body: #{res.body}", @log_tab_level
        @log_tab_level -= 1
        return JSON.parse(res.body)
      else
        Log.info "send_in_request: failed"
        @log_tab_level -= 1
        return nil
      end
    end

    def api_key
      Settings.two_captcha.api_key
    end
  end
end
