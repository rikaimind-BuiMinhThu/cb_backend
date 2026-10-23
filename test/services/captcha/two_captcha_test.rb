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

  def test_process_v3_returns_token_and_id
    captured_in_query = nil
    @client.http_queue = [
      lambda { |uri|
        captured_in_query = URI.decode_www_form(uri.query).to_h
        FakeResponse.new({ status: 1, request: "2122988149" }.to_json)
      },
      lambda { |_uri| FakeResponse.new({ status: 1, request: "CAPCHA_NOT_READY" }.to_json) },
      lambda { |_uri| FakeResponse.new({ status: 1, request: "03AHJ_token_sample" }.to_json) },
    ]

    result = @client.process_v3(
      sitekey: "6LfZil0UAAAAAAdm1Dpzsw9q0F11-bmervx9g5fE",
      page_url: "https://cart.mirai-japan.co.jp/order/signin",
      action: "verify",
      min_score: 0.3
    )

    assert_equal "03AHJ_token_sample", result[:token]
    assert_equal "2122988149", result[:id]
    assert_equal "userrecaptcha", captured_in_query["method"]
    assert_equal "v3", captured_in_query["version"]
    assert_equal "6LfZil0UAAAAAAdm1Dpzsw9q0F11-bmervx9g5fE", captured_in_query["googlekey"]
    assert_equal "https://cart.mirai-japan.co.jp/order/signin", captured_in_query["pageurl"]
    assert_equal "verify", captured_in_query["action"]
    assert_equal "0.3", captured_in_query["min_score"]
  end

  def test_report_good_hits_reportgood
    captured = nil
    @client.http_queue = [
      lambda { |uri|
        captured = URI.decode_www_form(uri.query).to_h
        FakeResponse.new({ status: 1, request: "OK_REPORT_RECORDED" }.to_json)
      },
    ]

    @client.report("2122988149", good: true)

    assert_equal "reportgood", captured["action"]
    assert_equal "2122988149", captured["id"]
    assert_equal "test-api-key", captured["key"]
  end

  def test_report_bad_hits_reportbad
    captured = nil
    @client.http_queue = [
      lambda { |uri|
        captured = URI.decode_www_form(uri.query).to_h
        FakeResponse.new({ status: 1, request: "OK_REPORT_RECORDED" }.to_json)
      },
    ]

    @client.report("2122988149", good: false)

    assert_equal "reportbad", captured["action"]
  end

  def test_process_v3_raises_when_sitekey_blank
    error = assert_raises(RuntimeError) do
      @client.process_v3(sitekey: "", page_url: "https://example.com")
    end
    assert_match(/sitekey/i, error.message)
  end
end
