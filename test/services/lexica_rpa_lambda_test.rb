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

module LexicaOrderCreateStub
  module_function

  def stub_order_create_with(created)
    relation = Object.new
    relation.define_singleton_method(:find_or_create_by!) do |attrs|
      created << attrs.merge(bot_type: :web)
      created.last
    end
    Order.stub(:create_with, ->(**_opts) { relation }) { yield }
  end
end

class LexicaActiveRecordResultSinkTest < ActiveSupport::TestCase
  include LexicaOrderCreateStub

  class FakeRecord
    attr_reader :attrs

    def initialize
      @attrs = {
        id: 1,
        client_id: 4,
        scenario_id: 8,
        user_input_id: "visitor",
        result: "running",
        order_submitted_at: nil,
        rpa_steps: [],
        last_step_no: 0,
        lexica_order_id: nil,
        error_kind: nil,
        error_message: nil
      }
    end

    def id
      @attrs[:id]
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

    def lexica_order_id
      @attrs[:lexica_order_id]
    end

    def last_step_no
      @attrs[:last_step_no]
    end

    def rpa_steps_array
      Array(@attrs[:rpa_steps])
    end

    def reload
      self
    end

    def update!(hash)
      @attrs.merge!(hash.transform_keys(&:to_sym))
    end
  end

  def test_mark_done_creates_one_order
    record = FakeRecord.new
    sink = SeleniumServices::Lexica::ActiveRecordResultSink.new(record)
    created = []
    stub_order_create_with(created) do
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

  def test_mark_failed_promotes_complete_url_to_done
    record = FakeRecord.new
    record.attrs[:rpa_steps] = [
      { "name" => "submit_order", "url" => "https://cart.mirai-japan.co.jp/order/complete/00900685", "ok" => false }
    ]
    sink = SeleniumServices::Lexica::ActiveRecordResultSink.new(record)
    created = []
    stub_order_create_with(created) do
      sink.mark_failed!(
        kind: "rpa_error",
        message: "Net::ReadTimeout",
        last_step_no: 9,
        last_step_description: "注文確定",
        screenshot_path: nil
      )
    end

    assert_equal 1, created.length
    assert_equal "done", record.attrs[:result].to_s
    assert_equal "00900685", record.attrs[:lexica_order_id]
    assert_nil record.attrs[:error_kind]
  end
end

class LexicaCompleteOrderSalvageTest < ActiveSupport::TestCase
  include LexicaOrderCreateStub

  def test_code_from_url_and_steps
    url = "https://cart.mirai-japan.co.jp/order/complete/00900685"
    assert_equal "00900685", SeleniumServices::Lexica::CompleteOrderSalvage.code_from_url(url)
    assert_equal(
      "00900685",
      SeleniumServices::Lexica::CompleteOrderSalvage.code_from_steps(
        [{ "url" => "https://cart.mirai-japan.co.jp/order/signin" }, { "url" => url }]
      )
    )
  end

  def test_salvage_job_promotes_via_sink
    record = LexicaActiveRecordResultSinkTest::FakeRecord.new
    record.attrs[:id] = 909
    record.attrs[:result] = "error"
    record.attrs[:error_kind] = "rpa_error"
    record.attrs[:rpa_steps] = [
      { "url" => "https://cart.mirai-japan.co.jp/order/complete/abc-99" }
    ]
    record.define_singleton_method(:reload) { self }
    record.define_singleton_method(:rpa_steps_array) { @attrs[:rpa_steps] }
    record.define_singleton_method(:lexica_order_id) { @attrs[:lexica_order_id] }
    record.define_singleton_method(:last_step_no) { @attrs[:last_step_no] }

    created = []
    stub_order_create_with(created) do
      assert SeleniumServices::Lexica::CompleteOrderSalvage.promote_record!(
        record,
        lexica_order_id: "abc-99",
        last_step_no: 3
      )
    end
    assert_equal "done", record.attrs[:result].to_s
    assert_equal "abc-99", record.attrs[:lexica_order_id]
    assert_equal 1, created.length
  end
end

class LexicaLambdaHandlerLoadTest < ActiveSupport::TestCase
  # No DB fixtures — only checks Lambda require order after the Checkout split.
  self.fixture_table_names = []

  def test_handler_requires_checkout_modules_before_checkout
    handler = File.read(Rails.root.join("rpa-lambda/handler.rb"))
    checkout_at = handler.index('lexica/checkout"')
    assert checkout_at, "handler must require checkout"

    %w[
      step_logging
      complete_order_salvage
      dom_actions
      cart_flow
      payment_delivery
      recaptcha
      complete_order
    ].each do |name|
      at = handler.index("lexica/#{name}\"")
      assert at, "handler must require #{name}"
      assert at < checkout_at, "#{name} must load before checkout"
    end
  end
end

class LexicaRpaEventsPatchLastStepTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  class FakeResult
    attr_reader :attrs

    def initialize(steps)
      @attrs = { rpa_steps: steps }
    end

    def rpa_steps_array
      Array(@attrs[:rpa_steps])
    end

    def update!(hash)
      @attrs.merge!(hash.transform_keys(&:to_sym))
      if hash.key?(:rpa_steps) || hash.key?("rpa_steps")
        raw = hash[:rpa_steps] || hash["rpa_steps"]
        @attrs[:rpa_steps] = JSON.parse(raw)
      end
    end
  end

  def test_patch_last_step_sets_screenshot_on_last_step
    result = FakeResult.new([{ "name" => "detect_result", "url" => "https://cart.example/order/complete/1" }])
    response = Lexica::RpaEvents.apply(
      result,
      event: "patch_last_step",
      screenshot_path: "rpa-screenshots/1/2/3_step9.png",
      step_no: 9
    )
    assert_equal true, response[:ok]
    assert_equal "rpa-screenshots/1/2/3_step9.png", result.attrs[:rpa_steps].last["screenshot_path"]
    assert_equal 9, result.attrs[:rpa_steps].last["step_no"]
  end
end
