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
    TOKEN_PLACEHOLDER = "[token]"

    def initialize(log_tab_level: 0)
      @log_tab_level = log_tab_level
    end

    # Returns {
    #   token:, id:,
    #   create_request:, create_response:,
    #   get_request:, get_response:
    # }
    def process_v3(sitekey:, page_url:, action: "verify", min_score: 0.3)
      @log_tab_level += 1
      Log.info "TwoCaptcha process_v3 sitekey=#{truncate(sitekey)} action=#{action}", @log_tab_level

      raise "TWO_CAPTCHA_API_KEY is blank" if api_key.to_s.strip.empty?
      raise "sitekey is blank" if sitekey.to_s.strip.empty?
      raise "page_url is blank" if page_url.to_s.strip.empty?

      create = create_task(
        method: "userrecaptcha",
        version: "v3",
        googlekey: sitekey,
        pageurl: page_url,
        action: action.presence || "verify",
        min_score: min_score,
        json: 1
      )
      id = create[:id]
      raise "2Captcha in.php returned no task id" if id.blank?

      get = poll_result(id)
      token = get[:token]
      raise "2Captcha returned empty token for id=#{id}" if token.blank?

      {
        token: token,
        id: id.to_s,
        create_request: create[:request],
        create_response: create[:response],
        get_request: get[:request],
        get_response: get[:response]
      }
    ensure
      @log_tab_level -= 1 if @log_tab_level.positive?
    end

    # Returns { request:, response: } or nil
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
      request_log = build_request_log(RES_URL, params)
      uri = URI(RES_URL)
      uri.query = URI.encode_www_form(params)
      res = http_get(uri)
      Log.info "TwoCaptcha report response: #{res&.body}", @log_tab_level
      body = parse_json_body(res&.body)
      { request: request_log, response: body }
    rescue StandardError => e
      Log.error "TwoCaptcha report failed: #{e.message}", @log_tab_level
      nil
    end

    private

    def create_task(**params)
      Log.info "TwoCaptcha create_task", @log_tab_level
      query = params.merge(key: api_key)
      request_log = build_request_log(IN_URL, query)
      uri = URI(IN_URL)
      uri.query = URI.encode_www_form(query)
      res = http_get(uri)
      raise "2Captcha in.php HTTP failure" unless res.is_a?(Net::HTTPSuccess)

      body = JSON.parse(res.body)
      Log.info "TwoCaptcha in.php body: #{body.inspect}", @log_tab_level
      raise "2Captcha in.php error: #{body['request']}" if body["status"].to_i != 1

      {
        id: body["request"].to_s,
        request: request_log,
        response: body
      }
    end

    def poll_result(id)
      Log.info "TwoCaptcha poll sleep #{INITIAL_WAIT_SECONDS}s id=#{id}", @log_tab_level
      sleep INITIAL_WAIT_SECONDS

      try_count = 1
      while try_count <= MAX_POLLS
        result = fetch_result(id)
        if result == :retry_again
          Log.info "TwoCaptcha CAPCHA_NOT_READY #{try_count}/#{MAX_POLLS}", @log_tab_level
          sleep POLL_INTERVAL_SECONDS
          try_count += 1
          next
        end
        return result
      end

      raise "2Captcha timeout waiting for id=#{id}"
    end

    def fetch_result(id)
      params = {
        key: api_key,
        action: "get",
        id: id,
        json: 1
      }
      request_log = build_request_log(RES_URL, params)
      uri = URI(RES_URL)
      uri.query = URI.encode_www_form(params)
      res = http_get(uri)
      raise "2Captcha res.php HTTP failure id=#{id}" unless res.is_a?(Net::HTTPSuccess)

      body = JSON.parse(res.body)
      request = body["request"].to_s
      return :retry_again if request == "CAPCHA_NOT_READY"
      raise "2Captcha res.php error: #{request}" if body["status"].to_i != 1

      {
        token: request,
        request: request_log,
        response: redact_token_in_response(body)
      }
    end

    def build_request_log(url, params)
      {
        "url" => url,
        "parameters" => sanitize_parameters(params)
      }
    end

    def sanitize_parameters(params)
      params.each_with_object({}) do |(key, value), out|
        name = key.to_s
        next if name == "key"

        out[name] = value.is_a?(Numeric) ? value : value.to_s
      end
    end

    def redact_token_in_response(body)
      return body unless body.is_a?(Hash)

      redacted = body.dup
      token = redacted["request"].to_s
      if token.present? && token != "CAPCHA_NOT_READY" && token.length > 20
        redacted["request"] = TOKEN_PLACEHOLDER
      end
      redacted
    end

    def parse_json_body(raw)
      return {} if raw.blank?

      JSON.parse(raw)
    rescue JSON::ParserError
      { "raw" => raw.to_s }
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
