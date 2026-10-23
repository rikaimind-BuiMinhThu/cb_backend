require "test_helper"
require "json"
require Rails.root.join("app/services/captcha/cap_solver")

class CaptchaCapSolverTest < ActiveSupport::TestCase
  # Pure unit test — skip DB fixtures from test_helper.
  def setup_fixtures; end
  def teardown_fixtures; end

  class FakeResponse
    attr_reader :body, :code

    def initialize(body, code: "200")
      @body = body
      @code = code
    end

    def is_a?(klass)
      return true if klass == Net::HTTPSuccess && code.to_i.between?(200, 299)

      super
    end
  end

  class TestClient < Captcha::CapSolver
    attr_accessor :http_queue

    def initialize
      super(log_tab_level: 0)
      @http_queue = []
    end

    def client_key
      "test-client-key"
    end

    def sleep(*)
      nil
    end

    def http_post(url, payload)
      raise "unexpected HTTP call: #{url}" if @http_queue.empty?

      @http_queue.shift.call(url, payload)
    end
  end

  def setup
    @client = TestClient.new
  end

  def test_process_v3_returns_token_id_identity_and_io_payloads
    captured_create = nil
    @client.http_queue = [
      lambda { |url, payload|
        assert_equal Captcha::CapSolver::CREATE_URL, url
        captured_create = payload
        FakeResponse.new({ errorId: 0, taskId: "task-abc-123" }.to_json)
      },
      lambda { |_url, _payload|
        FakeResponse.new({ errorId: 0, status: "processing" }.to_json)
      },
      lambda { |url, payload|
        assert_equal Captcha::CapSolver::GET_URL, url
        assert_equal "task-abc-123", payload["taskId"]
        FakeResponse.new(
          {
            errorId: 0,
            status: "ready",
            taskId: "task-abc-123",
            solution: {
              gRecaptchaResponse: "03AHJ_token_sample_long_enough_for_redact",
              userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
              secChUa: "\"Google Chrome\";v=\"149\"",
              "recaptcha-ca-t": "AbEM_session_cookie_sample"
            }
          }.to_json
        )
      },
    ]

    result = @client.process_v3(
      sitekey: "6LcBNZ8qAAAAAOcUa_sample_sitekey",
      page_url: "https://cart.mirai-japan.co.jp/order/signin",
      action: "e_commerce",
      min_score: 0.9
    )

    assert_equal "03AHJ_token_sample_long_enough_for_redact", result[:token]
    assert_equal "task-abc-123", result[:id]
    assert_equal "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", result[:user_agent]
    assert_equal "\"Google Chrome\";v=\"149\"", result[:sec_ch_ua]
    assert_equal "AbEM_session_cookie_sample", result[:session_cookie]
    assert_equal "test-client-key", captured_create["clientKey"]
    assert_equal Captcha::CapSolver::TASK_TYPE, captured_create["task"]["type"]
    assert_equal "6LcBNZ8qAAAAAOcUa_sample_sitekey", captured_create["task"]["websiteKey"]
    assert_equal "https://cart.mirai-japan.co.jp/order/signin", captured_create["task"]["websiteURL"]
    assert_equal "e_commerce", captured_create["task"]["pageAction"]
    assert_equal true, captured_create["task"]["isSession"]
    assert_nil captured_create["task"]["minScore"]

    create_request = result[:create_request]
    assert_equal Captcha::CapSolver::CREATE_URL, create_request["url"]
    assert_equal Captcha::CapSolver::TASK_TYPE, create_request["parameters"]["task"]["type"]
    assert_equal true, create_request["parameters"]["task"]["isSession"]
    assert_nil create_request["parameters"]["task"]["minScore"]
    assert_nil create_request["parameters"]["clientKey"]
    refute_includes JSON.generate(create_request), "test-client-key"
    assert_equal 0, result[:create_response]["errorId"]
    assert_equal "task-abc-123", result[:create_response]["taskId"]

    get_request = result[:get_request]
    assert_equal Captcha::CapSolver::GET_URL, get_request["url"]
    assert_equal "task-abc-123", get_request["parameters"]["taskId"]
    assert_nil get_request["parameters"]["clientKey"]
    refute_includes JSON.generate(get_request), "test-client-key"
    assert_equal Captcha::CapSolver::TOKEN_PLACEHOLDER, result[:get_response]["solution"]["gRecaptchaResponse"]
  end

  def test_report_good_calls_feedback_task_without_client_key_in_log
    captured = nil
    @client.http_queue = [
      lambda { |_url, _payload|
        FakeResponse.new({ errorId: 0, taskId: "task-abc-123" }.to_json)
      },
      lambda { |_url, _payload|
        FakeResponse.new(
          {
            errorId: 0,
            status: "ready",
            taskId: "task-abc-123",
            solution: { gRecaptchaResponse: "03AHJ_token_sample_long_enough_for_redact" }
          }.to_json
        )
      },
      lambda { |url, payload|
        assert_equal Captcha::CapSolver::FEEDBACK_URL, url
        captured = payload
        FakeResponse.new({ errorId: 0, message: "Thanks for your feedback" }.to_json)
      },
    ]

    @client.process_v3(
      sitekey: "6LcBNZ8qAAAAAOcUa_sample_sitekey",
      page_url: "https://cart.mirai-japan.co.jp/order/signin",
      action: "e_commerce"
    )
    result = @client.report("task-abc-123", good: true)

    assert_equal true, captured["solved"]
    assert_equal "test-client-key", captured["clientKey"]
    assert_equal Captcha::CapSolver::TASK_TYPE, captured["task"]["type"]
    assert_equal true, captured["task"]["isSession"]
    assert_equal Captcha::CapSolver::FEEDBACK_URL, result[:request]["url"]
    assert_equal true, result[:request]["parameters"]["solved"]
    assert_nil result[:request]["parameters"]["clientKey"]
    refute_includes JSON.generate(result[:request]), "test-client-key"
    assert_equal "Thanks for your feedback", result[:response]["message"]
  end

  def test_report_bad_sets_solved_false
    captured = nil
    @client.http_queue = [
      lambda { |_url, _payload|
        FakeResponse.new({ errorId: 0, taskId: "task-xyz" }.to_json)
      },
      lambda { |_url, _payload|
        FakeResponse.new(
          {
            errorId: 0,
            status: "ready",
            taskId: "task-xyz",
            solution: { gRecaptchaResponse: "03AHJ_token_sample_long_enough_for_redact" }
          }.to_json
        )
      },
      lambda { |_url, payload|
        captured = payload
        FakeResponse.new({ errorId: 0, message: "Thanks for your feedback" }.to_json)
      },
    ]

    @client.process_v3(
      sitekey: "6LcBNZ8qAAAAAOcUa_sample_sitekey",
      page_url: "https://cart.mirai-japan.co.jp/order/signin",
      action: "e_commerce"
    )
    result = @client.report("task-xyz", good: false)

    assert_equal false, captured["solved"]
    assert_equal false, result[:request]["parameters"]["solved"]
  end

  def test_report_always_returns_io_on_http_failure
    @client.http_queue = [
      lambda { |_url, _payload| raise "network down" },
    ]

    result = @client.report("task-orphan", good: false)

    assert result[:request].is_a?(Hash)
    assert result[:response].is_a?(Hash)
    assert_equal Captcha::CapSolver::FEEDBACK_URL, result[:request]["url"]
    assert_equal false, result[:request]["parameters"]["solved"]
    assert_equal "task-orphan", result[:request]["parameters"]["taskId"]
  end

  def test_process_v3_raises_when_sitekey_blank
    error = assert_raises(RuntimeError) do
      @client.process_v3(sitekey: "", page_url: "https://example.com")
    end
    assert_match(/sitekey/i, error.message)
  end
end
