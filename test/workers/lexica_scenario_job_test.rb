require "test_helper"
require "ostruct"
require "minitest/mock"

class LexicaScenarioJobTest < ActiveSupport::TestCase
  class FakeResult
    attr_reader :attrs

    def initialize(overrides = {})
      @attrs = {
        result: "running",
        last_step_description: "queued",
        error_kind: nil,
        error_message: nil,
        end_time: nil,
        scenario_id: 101,
        user_input_id: "uid-chrome-slot-test"
      }.merge(overrides)
    end

    def update!(hash)
      @attrs.merge!(hash.transform_keys(&:to_sym))
    end

    def result
      @attrs[:result]
    end

    def error_kind
      @attrs[:error_kind]
    end

    def last_step_description
      @attrs[:last_step_description]
    end

    def error_message
      @attrs[:error_message]
    end

    def end_time
      @attrs[:end_time]
    end

    def scenario_id
      @attrs[:scenario_id]
    end

    def user_input_id
      @attrs[:user_input_id]
    end

    def running?
      result.to_s == "running"
    end

    def open?
      result.to_s == "open"
    end
  end

  def setup
    @scenario_id = 101
    @user_id = "uid-chrome-slot-test"
    @result = FakeResult.new(scenario_id: @scenario_id, user_input_id: @user_id)
  end

  def test_timeout_on_attempt_0_requeues_with_attempt_1
    LexicaScenarioJob.stub(:find_result, @result) do
      scheduled = nil
      LexicaScenarioJob.stub(
        :perform_in,
        ->(delay, scenario_id, user_id, attempt, *_) {
          scheduled = [delay, scenario_id, user_id, attempt]
        }
      ) do
        LexicaScenarioJob.schedule_chrome_slot_retry_or_fail(
          @scenario_id,
          @user_id,
          "chrome_slot_timeout",
          "lexica chrome slot wait timed out",
          0
        )
      end

      assert_equal LexicaScenarioJob::CHROME_SLOT_RETRY_DELAY, scheduled[0]
      assert_equal [@scenario_id, @user_id, 1], scheduled[1..]
      assert_equal "running", @result.result
      assert_equal "queued", @result.last_step_description
      assert_nil @result.error_kind
    end
  end

  def test_timeout_on_attempt_3_marks_final_error_without_requeue
    LexicaScenarioJob.stub(:find_result, @result) do
      called = false
      LexicaScenarioJob.stub(:perform_in, ->(*) { called = true }) do
        LexicaScenarioJob.schedule_chrome_slot_retry_or_fail(
          @scenario_id,
          @user_id,
          "chrome_slot_timeout",
          "lexica chrome slot wait timed out",
          LexicaScenarioJob::CHROME_SLOT_MAX_RETRIES
        )
      end

      refute called
      assert_equal "error", @result.result.to_s
      assert_equal "chrome_slot_timeout", @result.error_kind
      assert_match(/retries exhausted/, @result.error_message)
    end
  end

  def build_scenario_stub
    responses = Object.new
    responses.define_singleton_method(:where) { |*| [] }
    OpenStruct.new(
      chatbot: OpenStruct.new(user: OpenStruct.new(client: Object.new)),
      scenario_user_responses: responses
    )
  end

  def stub_offer_resolver
    resolver = Object.new
    resolver.define_singleton_method(:resolve!) { true }
    SeleniumServices::Lexica::OfferResolver.stub(:new, ->(*) { resolver }) do
      yield
    end
  end

  def test_perform_defers_when_acquire_fails
    job = LexicaScenarioJob.new
    scenario = build_scenario_stub
    slot = Object.new
    started_at = Time.now.to_i - 10
    scheduled = nil

    Scenario.stub(:find, scenario) do
      job.stub(:find_result, @result) do
        stub_offer_resolver do
          SeleniumServices::ChromeSlot.stub(:new, slot) do
            slot.define_singleton_method(:acquire) { false }
            LexicaScenarioJob.stub(
              :perform_in,
              ->(delay, scenario_id, user_id, attempt, wait_started) {
                scheduled = [delay, scenario_id, user_id, attempt, wait_started]
              }
            ) do
              job.perform(@scenario_id, @user_id, 0, started_at)
            end
          end
        end
      end
    end

    assert_equal LexicaScenarioJob::SLOT_DEFER_DELAY, scheduled[0]
    assert_equal [@scenario_id, @user_id, 0, started_at], scheduled[1..]
    assert_equal "queued", @result.last_step_description
  end

  def test_perform_wall_timeout_schedules_chrome_slot_retry
    job = LexicaScenarioJob.new
    scenario = build_scenario_stub
    started_at = Time.now.to_i - SeleniumServices::ChromeSlot::WAIT_SECONDS - 1
    called = nil

    Scenario.stub(:find, scenario) do
      job.stub(:find_result, @result) do
        stub_offer_resolver do
          LexicaScenarioJob.stub(
            :schedule_chrome_slot_retry_or_fail,
            ->(scenario_id, user_id, kind, _msg, attempt) {
              called = [scenario_id, user_id, kind, attempt]
            }
          ) do
            job.perform(@scenario_id, @user_id, 1, started_at)
          end
        end
      end
    end

    assert_equal [@scenario_id, @user_id, "chrome_slot_timeout", 1], called
  end

  def test_recover_chrome_slot_orphan_schedules_retry
    scheduled = nil
    LexicaScenarioJob.stub(:find_result, @result) do
      LexicaScenarioJob.stub(
        :perform_in,
        ->(delay, scenario_id, user_id, attempt, *_) {
          scheduled = [delay, scenario_id, user_id, attempt]
        }
      ) do
        LexicaScenarioJob.recover_chrome_slot_orphan!(@result)
      end
    end

    assert_equal LexicaScenarioJob::CHROME_SLOT_RETRY_DELAY, scheduled[0]
    assert_equal [@scenario_id, @user_id, 1], scheduled[1..]
  end
end

class LexicaChromeSlotOrphanReaperJobTest < ActiveSupport::TestCase
  def test_reaper_recovers_stale_queued_rows
    stale = Object.new
    stale.define_singleton_method(:id) { 99 }
    stale.define_singleton_method(:scenario_id) { 1 }
    stale.define_singleton_method(:user_input_id) { "u1" }

    relation = Object.new
    relation.define_singleton_method(:where) { |*| relation }
    relation.define_singleton_method(:find_each) { |&blk| blk.call(stale) }

    recovered = nil
    ScenarioUserResponseSeleniumResult.stub(:where, ->(*) { relation }) do
      LexicaScenarioJob.stub(:recover_chrome_slot_orphan!, ->(row) { recovered = row }) do
        LexicaChromeSlotOrphanReaperJob.new.perform
      end
    end

    assert_equal stale, recovered
  end
end
