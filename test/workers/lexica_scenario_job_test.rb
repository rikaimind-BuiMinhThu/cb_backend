require "test_helper"
require "ostruct"
require "minitest/mock"

class LexicaScenarioJobTest < ActiveSupport::TestCase
  class FakeResult
    attr_reader :attrs

    def initialize
      @attrs = {
        result: "running",
        last_step_description: "queued",
        error_kind: nil,
        error_message: nil,
        end_time: nil
      }
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
  end

  def setup
    @job = LexicaScenarioJob.new
    @result = FakeResult.new
    @scenario_id = 101
    @user_id = "uid-chrome-slot-test"
  end

  def test_timeout_on_attempt_0_requeues_with_attempt_1
    @job.stub(:find_result, @result) do
      scheduled = nil
      LexicaScenarioJob.stub(
        :perform_in,
        ->(delay, scenario_id, user_id, attempt) {
          scheduled = [delay, scenario_id, user_id, attempt]
        }
      ) do
        @job.send(
          :schedule_chrome_slot_retry_or_fail,
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
      assert_nil @result.error_message
      assert_nil @result.end_time
    end
  end

  def test_timeout_on_attempt_3_marks_final_error_without_requeue
    @job.stub(:find_result, @result) do
      called = false
      LexicaScenarioJob.stub(:perform_in, ->(*) { called = true }) do
        @job.send(
          :schedule_chrome_slot_retry_or_fail,
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
      assert_match(/retries exhausted after #{LexicaScenarioJob::CHROME_SLOT_MAX_RETRIES}/, @result.error_message)
      assert_not_nil @result.end_time
    end
  end

  def test_orphan_kind_also_retries_when_attempts_remain
    @job.stub(:find_result, @result) do
      scheduled_attempt = nil
      LexicaScenarioJob.stub(
        :perform_in,
        ->(_delay, _scenario_id, _user_id, attempt) { scheduled_attempt = attempt }
      ) do
        @job.send(
          :schedule_chrome_slot_retry_or_fail,
          @scenario_id,
          @user_id,
          "chrome_slot_orphan",
          "slot counter leaked",
          2
        )
      end

      assert_equal 3, scheduled_attempt
      assert_equal "queued", @result.last_step_description
    end
  end
end
