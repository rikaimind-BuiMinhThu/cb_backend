require File.dirname(__FILE__) + "/../log"
require "uri"
require "net/http"
require "cgi"
require "json"

module Captcha
  class TwoCaptcha
    IN_URL = "https://2captcha.com/in.php"
    RES_URL = "https://2captcha.com/res.php"
    INITIAL_WAIT_SECONDS = 15
    POLL_INTERVAL_SECONDS = 5
    MAX_POLLS = 30

    def initialize(log_tab_level: 0)
      @log_tab_level = log_tab_level
    end

    # Returns { token: String, id: String }
    def process_v3(sitekey:, page_url:, action: "verify", min_score: 0.3)
      @log_tab_level += 1
      Log.info "TwoCaptcha process_v3 sitekey=#{truncate(sitekey)} action=#{action}", @log_tab_level

      raise "TWO_CAPTCHA_API_KEY is blank" if api_key.to_s.strip.empty?
      raise "sitekey is blank" if sitekey.to_s.strip.empty?
      raise "page_url is blank" if page_url.to_s.strip.empty?

      id = create_task(
        method: "userrecaptcha",
        version: "v3",
        googlekey: sitekey,
        pageurl: page_url,
        action: action.presence || "verify",
        min_score: min_score,
        json: 1
      )
      raise "2Captcha in.php returned no task id" if id.blank?

      token = poll_result(id)
      raise "2Captcha returned empty token for id=#{id}" if token.blank?

      { token: token, id: id.to_s }
    ensure
      @log_tab_level -= 1 if @log_tab_level.positive?
    end

    def report(id, good:)
      return if id.blank?

      action = good ? "reportgood" : "reportbad"
      Log.info "TwoCaptcha report #{action} id=#{id}", @log_tab_level
      params = {
        key: api_key,
        action: action,
        id: id,
        json: 1
      }
      uri = URI(RES_URL)
      uri.query = URI.encode_www_form(params)
      res = http_get(uri)
      Log.info "TwoCaptcha report response: #{res&.body}", @log_tab_level
      res
    rescue StandardError => e
      Log.error "TwoCaptcha report failed: #{e.message}", @log_tab_level
      nil
    end

    private

    def create_task(**params)
      Log.info "TwoCaptcha create_task", @log_tab_level
      query = params.merge(key: api_key)
      uri = URI(IN_URL)
      uri.query = URI.encode_www_form(query)
      res = http_get(uri)
      raise "2Captcha in.php HTTP failure" unless res.is_a?(Net::HTTPSuccess)

      body = JSON.parse(res.body)
      Log.info "TwoCaptcha in.php body: #{body.inspect}", @log_tab_level
      raise "2Captcha in.php error: #{body['request']}" if body["status"].to_i != 1

      body["request"].to_s
    end

    def poll_result(id)
      Log.info "TwoCaptcha poll sleep #{INITIAL_WAIT_SECONDS}s id=#{id}", @log_tab_level
      sleep INITIAL_WAIT_SECONDS

      try_count = 1
      while try_count <= MAX_POLLS
        response = fetch_result(id)
        if response == :retry_again
          Log.info "TwoCaptcha CAPCHA_NOT_READY #{try_count}/#{MAX_POLLS}", @log_tab_level
          sleep POLL_INTERVAL_SECONDS
          try_count += 1
          next
        end
        return response
      end

      raise "2Captcha timeout waiting for id=#{id}"
    end

    def fetch_result(id)
      uri = URI(RES_URL)
      uri.query = URI.encode_www_form(
        key: api_key,
        action: "get",
        id: id,
        json: 1
      )
      res = http_get(uri)
      raise "2Captcha res.php HTTP failure id=#{id}" unless res.is_a?(Net::HTTPSuccess)

      body = JSON.parse(res.body)
      request = body["request"].to_s
      return :retry_again if request == "CAPCHA_NOT_READY"
      raise "2Captcha res.php error: #{request}" if body["status"].to_i != 1

      request
    end

    def http_get(uri)
      Net::HTTP.get_response(uri)
    end

    def api_key
      Settings.two_captcha.api_key
    end

    def truncate(value)
      text = value.to_s
      return text if text.length <= 12

      "#{text[0, 6]}…#{text[-4, 4]}"
    end
  end
end
