require "test_helper"

class LexicaChromePackTest < ActiveSupport::TestCase
  def test_pack_d_uses_720p_and_blocks_images
    assert_equal "1280,720", SeleniumServices::Lexica::Base::WINDOW_SIZE
    blocked = SeleniumServices::Lexica::Base::BLOCKED_URLS
    assert_includes blocked, "*google-analytics*"
    assert blocked.any? { |pattern| pattern.include?("png") }
    assert blocked.any? { |pattern| pattern.include?("jpg") }
  end
end

class LexicaRpaClaimTest < ActiveSupport::TestCase
  class FakeResult
    attr_reader :attrs

    def initialize(overrides = {})
      @attrs = {
        result: "running",
        order_submitted_at: nil,
        rpa_attempt: 0,
        claimed_at: nil,
        end_time: nil,
        defer_started_at: nil,
        last_step_description: "queued",
        error_kind: nil,
        client_id: 7,
        id: 9
      }.merge(overrides)
    end

    def update!(hash)
      @attrs.merge!(hash.transform_keys(&:to_sym))
    end

    def done?
      @attrs[:result].to_s == "done"
    end

    def error?
      @attrs[:result].to_s == "error"
    end

    def running?
      @attrs[:result].to_s == "running"
    end

    def retryable?
      return false if order_submitted_at.present?

      error?
    end

    def order_submitted_at
      @attrs[:order_submitted_at]
    end

    def rpa_attempt
      @attrs[:rpa_attempt]
    end

    def claimed_at
      @attrs[:claimed_at]
    end

    def end_time
      @attrs[:end_time]
    end

    def defer_started_at
      @attrs[:defer_started_at]
    end

    def id
      @attrs[:id]
    end

    def client_id
      @attrs[:client_id]
    end
  end

  def test_skip_when_done_does_not_build_a_job
    result = FakeResult.new(result: "done")
    Lexica::JobPayload.stub(:build, ->(*) { flunk "payload built" }) do
      decision = Lexica::RpaClaim.call(result, client_cap: nil, in_flight_count: 0)
      assert_equal "skip", decision[:action]
      assert_equal "done", decision[:reason]
    end
  end

  def test_skip_when_order_already_submitted
    result = FakeResult.new(order_submitted_at: Time.current, rpa_attempt: 1)
    Lexica::JobPayload.stub(:build, ->(*) { flunk "payload built" }) do
      decision = Lexica::RpaClaim.call(result, client_cap: nil, in_flight_count: 0)
      assert_equal "skip", decision[:action]
      assert_equal "submitted", decision[:reason]
    end
    assert_equal 1, result.rpa_attempt
  end

  def test_defer_does_not_increment_attempt
    result = FakeResult.new(rpa_attempt: 1)
    decision = Lexica::RpaClaim.call(result, client_cap: 1, in_flight_count: 1)
    assert_equal "defer", decision[:action]
    assert_equal 30, decision[:retry_after]
    assert_equal 1, result.rpa_attempt
    assert result.defer_started_at.present?
  end

  def test_second_claim_while_in_flight_does_not_start_checkout
    result = FakeResult.new(claimed_at: Time.current, rpa_attempt: 1)
    Lexica::JobPayload.stub(:build, ->(*) { flunk "payload built" }) do
      decision = Lexica::RpaClaim.call(result, client_cap: nil, in_flight_count: 0, now: Time.current)
      assert_equal "skip", decision[:action]
      assert_equal "in_flight", decision[:reason]
    end
    assert_equal 1, result.rpa_attempt
  end

  def test_run_increments_attempt_once
    result = FakeResult.new
    payload = { "result_id" => 9 }
    Lexica::JobPayload.stub(:build, payload) do
      decision = Lexica::RpaClaim.call(result, client_cap: nil, in_flight_count: 0)
      assert_equal "run", decision[:action]
      assert_equal payload, decision[:job]
    end
    assert_equal 1, result.rpa_attempt
    assert_equal "running", result.attrs[:result].to_s
  end
end

class LexicaRpaDispatchTest < ActiveSupport::TestCase
  def test_defer_requeues_and_skip_finishes
    assert_equal :requeue, Lexica::RpaDispatch.action_for("action" => "defer")
    assert_equal :run, Lexica::RpaDispatch.action_for("action" => "run")
    assert_equal :finish, Lexica::RpaDispatch.action_for("action" => "skip")
  end
end

class LexicaJobPayloadCardTest < ActiveSupport::TestCase
  def test_card_payload_keeps_token_and_drops_pan
    raw = JSON.generate(
      "token_key" => "tok-1",
      "card_number" => "4111111111111111",
      "cvc" => "123"
    )
    cleaned = JSON.parse(Lexica::JobPayload.card_for_lambda(raw))
    assert_equal "tok-1", cleaned["token_key"]
    refute cleaned.key?("card_number")
    refute cleaned.key?("cvc")
  end
end

class LexicaActiveRecordResultSinkTest < ActiveSupport::TestCase
  class FakeRecord
    attr_reader :attrs

    def initialize
      @attrs = {
        client_id: 4,
        scenario_id: 8,
        user_input_id: "visitor",
        result: "running",
        order_submitted_at: nil
      }
    end

    def client_id
      @attrs[:client_id]
    end

    def scenario_id
      @attrs[:scenario_id]
    end

    def user_input_id
      @attrs[:user_input_id]
    end

    def done?
      @attrs[:result].to_s == "done"
    end

    def order_submitted_at
      @attrs[:order_submitted_at]
    end

    def update!(hash)
      @attrs.merge!(hash.transform_keys(&:to_sym))
    end
  end

  def test_mark_done_creates_one_order
    record = FakeRecord.new
    sink = SeleniumServices::Lexica::ActiveRecordResultSink.new(record)
    created = []
    Order.stub(:create!, ->(**attrs) { created << attrs }) do
      sink.mark_done!(lexica_order_id: "L-1", last_step_no: 4, last_step_description: "完了を確認")
      sink.mark_done!(lexica_order_id: "L-1", last_step_no: 4, last_step_description: "完了を確認")
    end

    assert_equal 1, created.length
    assert_equal 4, created[0][:client_id]
    assert_equal 8, created[0][:scenario_id]
    assert_equal "visitor", created[0][:user_input_id]
    assert_equal :web, created[0][:bot_type]
    assert_equal "done", record.attrs[:result].to_s
    assert_equal "L-1", record.attrs[:lexica_order_id]
  end

  def test_mark_submitted_sets_timestamp_once
    record = FakeRecord.new
    sink = SeleniumServices::Lexica::ActiveRecordResultSink.new(record)
    sink.mark_submitted!
    first = record.order_submitted_at
    sink.mark_submitted!
    assert_equal first, record.order_submitted_at
  end
end
