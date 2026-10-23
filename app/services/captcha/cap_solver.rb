require File.dirname(__FILE__) + "/../log"
require "uri"
require "net/http"
require "json"

module Captcha
  class CapSolver
    CREATE_URL = "https://api.capsolver.com/createTask"
    GET_URL = "https://api.capsolver.com/getTaskResult"
    FEEDBACK_URL = "https://api.capsolver.com/feedbackTask"
    TASK_TYPE = "ReCaptchaV3TaskProxyLess"
    INITIAL_WAIT_SECONDS = 5
    POLL_INTERVAL_SECONDS = 3
    MAX_POLLS = 40
    TOKEN_PLACEHOLDER = "[token]"

    def initialize(log_tab_level: 0)
      @log_tab_level = log_tab_level
      @last_task = nil
      @last_result = nil
    end

    # Returns {
    #   token:, id:,
    #   create_request:, create_response:,
    #   get_request:, get_response:
    # }
    def process_v3(sitekey:, page_url:, action: "verify", min_score: 0.9)
      @log_tab_level += 1
      Log.info "CapSolver process_v3 sitekey=#{truncate(sitekey)} action=#{action}", @log_tab_level

      raise "CAPTCHA_CLIENT_KEY is blank" if client_key.to_s.strip.empty?
      raise "sitekey is blank" if sitekey.to_s.strip.empty?
      raise "page_url is blank" if page_url.to_s.strip.empty?

      task = {
        "type" => TASK_TYPE,
        "websiteURL" => page_url,
        "websiteKey" => sitekey,
        "pageAction" => action.presence || "verify",
        "minScore" => min_score.to_f
      }
      @last_task = task
      @last_result = nil

      create = create_task(task)
      id = create[:id]
      raise "CapSolver createTask returned no taskId" if id.blank?

      get = poll_result(id)
      token = get[:token]
      raise "CapSolver returned empty token for taskId=#{id}" if token.blank?

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

    # Always returns { request:, response: } (never nil on happy path).
    def report(id, good:)
      return stub_report(id, good: good, reason: "blank_task_id") if id.blank?

      Log.info "CapSolver report solved=#{good} taskId=#{id}", @log_tab_level
      payload = {
        "clientKey" => client_key,
        "solved" => !!good,
        "task" => @last_task.presence || { "type" => TASK_TYPE },
        "result" => @last_result.presence || {
          "errorId" => 0,
          "taskId" => id.to_s,
          "status" => "ready"
        }
      }
      request_log = build_request_log(FEEDBACK_URL, payload)
      res = http_post(FEEDBACK_URL, payload)
      body = parse_json_body(res&.body)
      Log.info "CapSolver feedbackTask response: #{body.inspect}", @log_tab_level
      { request: request_log, response: body }
    rescue StandardError => e
      Log.error "CapSolver report failed: #{e.message}", @log_tab_level
      stub_report(id, good: good, reason: e.message)
    end

    private

    def create_task(task)
      Log.info "CapSolver create_task type=#{task['type']}", @log_tab_level
      payload = {
        "clientKey" => client_key,
        "task" => task
      }
      request_log = build_request_log(CREATE_URL, payload)
      res = http_post(CREATE_URL, payload)
      body = parse_json_body(res&.body)
      Log.info "CapSolver createTask body: #{body.inspect}", @log_tab_level
      unless res.is_a?(Net::HTTPSuccess)
        detail = body["errorDescription"].presence || body["errorCode"].presence || res&.body.to_s.truncate(200)
        raise "CapSolver createTask HTTP #{res&.code}: #{detail}"
      end
      raise "CapSolver createTask error: #{body['errorDescription'] || body['errorCode']}" if body["errorId"].to_i != 0

      id = body["taskId"].to_s
      raise "CapSolver createTask missing taskId" if id.blank?

      {
        id: id,
        request: request_log,
        response: body
      }
    end

    def poll_result(id)
      Log.info "CapSolver poll sleep #{INITIAL_WAIT_SECONDS}s taskId=#{id}", @log_tab_level
      sleep INITIAL_WAIT_SECONDS

      try_count = 1
      while try_count <= MAX_POLLS
        result = fetch_result(id)
        if result == :retry_again
          Log.info "CapSolver processing #{try_count}/#{MAX_POLLS}", @log_tab_level
          sleep POLL_INTERVAL_SECONDS
          try_count += 1
          next
        end
        return result
      end

      raise "CapSolver timeout waiting for taskId=#{id}"
    end

    def fetch_result(id)
      payload = {
        "clientKey" => client_key,
        "taskId" => id
      }
      request_log = build_request_log(GET_URL, payload)
      res = http_post(GET_URL, payload)
      body = parse_json_body(res&.body)
      unless res.is_a?(Net::HTTPSuccess)
        detail = body["errorDescription"].presence || body["errorCode"].presence || res&.body.to_s.truncate(200)
        raise "CapSolver getTaskResult HTTP #{res&.code} taskId=#{id}: #{detail}"
      end
      raise "CapSolver getTaskResult error: #{body['errorDescription'] || body['errorCode']}" if body["errorId"].to_i != 0

      status = body["status"].to_s
      return :retry_again if status == "idle" || status == "processing"

      raise "CapSolver getTaskResult unexpected status=#{status}" if status != "ready"

      token = body.dig("solution", "gRecaptchaResponse").to_s
      @last_result = body
      {
        token: token,
        request: request_log,
        response: redact_token_in_response(body)
      }
    end

    def stub_report(id, good:, reason:)
      payload = {
        "solved" => !!good,
        "taskId" => id.to_s,
        "valid" => !!good,
        "stub" => true,
        "reason" => reason.to_s
      }
      {
        request: build_request_log(FEEDBACK_URL, payload),
        response: { "errorId" => 0, "message" => "local stub", "reason" => reason.to_s }
      }
    end

    def build_request_log(url, params)
      {
        "url" => url,
        "parameters" => sanitize_parameters(params)
      }
    end

    def sanitize_parameters(params)
      return {} unless params.is_a?(Hash)

      params.each_with_object({}) do |(key, value), out|
        name = key.to_s
        next if name == "clientKey" || name == "client_key"

        out[name] = sanitize_value(value)
      end
    end

    def sanitize_value(value)
      case value
      when Hash
        sanitize_parameters(value)
      when Array
        value.map { |item| sanitize_value(item) }
      when Numeric, TrueClass, FalseClass, NilClass
        value
      else
        value.to_s
      end
    end

    def redact_token_in_response(body)
      return body unless body.is_a?(Hash)

      redacted = deep_dup_hash(body)
      solution = redacted["solution"]
      if solution.is_a?(Hash)
        token = solution["gRecaptchaResponse"].to_s
        solution["gRecaptchaResponse"] = TOKEN_PLACEHOLDER if token.length > 20
      end
      redacted
    end

    def deep_dup_hash(value)
      case value
      when Hash
        value.each_with_object({}) { |(k, v), out| out[k] = deep_dup_hash(v) }
      when Array
        value.map { |item| deep_dup_hash(item) }
      else
        value
      end
    end

    def parse_json_body(raw)
      return {} if raw.blank?

      JSON.parse(raw)
    rescue JSON::ParserError
      { "raw" => raw.to_s }
    end

    def http_post(url, payload)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)
      http.request(request)
    end

    def client_key
      Settings.captcha.client_key
    end

    def truncate(value)
      text = value.to_s
      return text if text.length <= 12

      "#{text[0, 6]}…#{text[-4, 4]}"
    end
  end
end
