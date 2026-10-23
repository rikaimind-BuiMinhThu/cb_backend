require "test_helper"
require "json"
require Rails.root.join("app/services/captcha/two_captcha")

class CaptchaTwoCaptchaTest < ActiveSupport::TestCase
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

  class TestClient < Captcha::TwoCaptcha
    attr_accessor :http_queue

    def initialize
      super(log_tab_level: 0)
      @http_queue = []
    end

    def api_key
      "test-api-key"
    end

    def sleep(*)
      nil
    end

    def http_get(uri)
      raise "unexpected HTTP call: #{uri}" if @http_queue.empty?

      @http_queue.shift.call(uri)
    end
  end

  def setup
    @client = TestClient.new
  end

  def test_process_v3_returns_token_id_and_io_payloads
    captured_in_query = nil
    @client.http_queue = [
      lambda { |uri|
        captured_in_query = URI.decode_www_form(uri.query).to_h
        FakeResponse.new({ status: 1, request: "2122988149" }.to_json)
      },
      lambda { |_uri| FakeResponse.new({ status: 1, request: "CAPCHA_NOT_READY" }.to_json) },
      lambda { |_uri| FakeResponse.new({ status: 1, request: "03AHJ_token_sample_long_enough" }.to_json) },
    ]

    result = @client.process_v3(
      sitekey: "6LfZil0UAAAAAAdm1Dpzsw9q0F11-bmervx9g5fE",
      page_url: "https://cart.mirai-japan.co.jp/order/signin",
      action: "verify",
      min_score: 0.3
    )

    assert_equal "03AHJ_token_sample_long_enough", result[:token]
    assert_equal "2122988149", result[:id]
    assert_equal "userrecaptcha", captured_in_query["method"]
    assert_equal "v3", captured_in_query["version"]
    assert_equal "6LfZil0UAAAAAAdm1Dpzsw9q0F11-bmervx9g5fE", captured_in_query["googlekey"]
    assert_equal "https://cart.mirai-japan.co.jp/order/signin", captured_in_query["pageurl"]
    assert_equal "verify", captured_in_query["action"]
    assert_equal "0.3", captured_in_query["min_score"]

    create_request = result[:create_request]
    assert_equal Captcha::TwoCaptcha::IN_URL, create_request["url"]
    assert_equal "userrecaptcha", create_request["parameters"]["method"]
    assert_nil create_request["parameters"]["key"]
    refute_includes JSON.generate(create_request), "test-api-key"
    assert_equal 1, result[:create_response]["status"]
    assert_equal "2122988149", result[:create_response]["request"]

    get_request = result[:get_request]
    assert_equal Captcha::TwoCaptcha::RES_URL, get_request["url"]
    assert_equal "get", get_request["parameters"]["action"]
    assert_equal "2122988149", get_request["parameters"]["id"]
    assert_nil get_request["parameters"]["key"]
    assert_equal Captcha::TwoCaptcha::TOKEN_PLACEHOLDER, result[:get_response]["request"]
  end

  def test_report_good_returns_request_response_without_key
    captured = nil
    @client.http_queue = [
      lambda { |uri|
        captured = URI.decode_www_form(uri.query).to_h
        FakeResponse.new({ status: 1, request: "OK_REPORT_RECORDED" }.to_json)
      },
    ]

    result = @client.report("2122988149", good: true)

    assert_equal "reportgood", captured["action"]
    assert_equal "2122988149", captured["id"]
    assert_equal "test-api-key", captured["key"]
    assert_equal Captcha::TwoCaptcha::RES_URL, result[:request]["url"]
    assert_equal "reportgood", result[:request]["parameters"]["action"]
    assert_nil result[:request]["parameters"]["key"]
    refute_includes JSON.generate(result[:request]), "test-api-key"
    assert_equal "OK_REPORT_RECORDED", result[:response]["request"]
  end

  def test_report_bad_hits_reportbad
    captured = nil
    @client.http_queue = [
      lambda { |uri|
        captured = URI.decode_www_form(uri.query).to_h
        FakeResponse.new({ status: 1, request: "OK_REPORT_RECORDED" }.to_json)
      },
    ]

    result = @client.report("2122988149", good: false)

    assert_equal "reportbad", captured["action"]
    assert_equal "reportbad", result[:request]["parameters"]["action"]
  end

  def test_process_v3_raises_when_sitekey_blank
    error = assert_raises(RuntimeError) do
      @client.process_v3(sitekey: "", page_url: "https://example.com")
    end
    assert_match(/sitekey/i, error.message)
  end
end
