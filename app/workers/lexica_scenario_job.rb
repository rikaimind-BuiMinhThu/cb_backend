class LexicaScenarioJob
  include Sidekiq::Worker
  sidekiq_options queue: :lexica, retry: 0

  CHROME_SLOT_MAX_RETRIES = 3
  CHROME_SLOT_RETRY_DELAY = 15.seconds
  CHROME_SLOT_ERROR_KINDS = %w[chrome_slot_timeout chrome_slot_orphan].freeze
  SLOT_DEFER_DELAY = SeleniumServices::ChromeSlot::DEFER_SECONDS.seconds
  RPA_STEP_DEFER = "chrome_slot_defer"
  RPA_STEP_RETRY = "chrome_slot_retry"

  def perform(scenario_id, user_id, chrome_slot_attempt = 0, slot_wait_started_at = nil)
    chrome_slot_attempt = chrome_slot_attempt.to_i
    slot_wait_started_at = (slot_wait_started_at || Time.now.to_i).to_i
    scenario = Scenario.find(scenario_id)
    client = scenario.chatbot&.user&.client
    conversations = scenario.scenario_user_responses.where(user_input_id: user_id)
    result = find_result(scenario_id, user_id)

    begin
      SeleniumServices::Lexica::OfferResolver.new(scenario, conversations).resolve!
    rescue SeleniumServices::Lexica::OfferError => e
      mark_error(scenario_id, user_id, e.error_kind, e.message)
      return
    end

    if Time.now.to_i - slot_wait_started_at >= SeleniumServices::ChromeSlot::WAIT_SECONDS
      self.class.schedule_chrome_slot_retry_or_fail(
        scenario_id,
        user_id,
        "chrome_slot_timeout",
        "lexica chrome slot wait timed out",
        chrome_slot_attempt
      )
      return
    end

    slot = SeleniumServices::ChromeSlot.new(client)
    unless slot.acquire
      wait_elapsed = Time.now.to_i - slot_wait_started_at
      self.class.append_chrome_slot_defer!(result, chrome_slot_attempt, wait_elapsed)
      result&.update!(last_step_description: "queued")
      Rails.logger.info(
        "LexicaScenarioJob chrome_slot defer scenario_id=#{scenario_id} user_id=#{user_id} " \
        "attempt=#{chrome_slot_attempt} wait_elapsed=#{wait_elapsed}s"
      )
      self.class.perform_in(
        SLOT_DEFER_DELAY,
        scenario_id,
        user_id,
        chrome_slot_attempt,
        slot_wait_started_at
      )
      return
    end

    begin
      result&.update!(last_step_description: "running", start_time: Time.current)
      service = SeleniumServices::Lexica.build(scenario, conversations)
      service.process
    ensure
      slot.release_if_acquired
    end
  rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError => e
    mark_error(scenario_id, user_id, "alert", e.message)
  rescue Timeout::Error => e
    self.class.schedule_chrome_slot_retry_or_fail(
      scenario_id,
      user_id,
      "chrome_slot_timeout",
      e.message,
      chrome_slot_attempt
    )
  rescue => e
    mark_error(scenario_id, user_id, "rpa_error", e.message)
  end

  def self.recover_chrome_slot_orphan!(result)
    return unless result
    return unless result.running? || result.open?

    schedule_chrome_slot_retry_or_fail(
      result.scenario_id,
      result.user_input_id,
      "chrome_slot_orphan",
      "stale queued row recovered by reaper",
      0
    )
  end

  def self.schedule_chrome_slot_retry_or_fail(scenario_id, user_id, kind, message, chrome_slot_attempt)
    chrome_slot_attempt = chrome_slot_attempt.to_i
    unless CHROME_SLOT_ERROR_KINDS.include?(kind.to_s)
      mark_error(scenario_id, user_id, kind, message)
      return
    end

    if chrome_slot_attempt < CHROME_SLOT_MAX_RETRIES
      reset_result_for_chrome_slot_retry(scenario_id, user_id)
      next_attempt = chrome_slot_attempt + 1
      result = find_result(scenario_id, user_id)
      append_chrome_slot_retry!(result, next_attempt, kind)
      Rails.logger.info(
        "LexicaScenarioJob chrome_slot retry scenario_id=#{scenario_id} user_id=#{user_id} " \
        "kind=#{kind} next_attempt=#{next_attempt}/#{CHROME_SLOT_MAX_RETRIES}"
      )
      perform_in(CHROME_SLOT_RETRY_DELAY, scenario_id, user_id, next_attempt)
    else
      mark_error(
        scenario_id,
        user_id,
        kind,
        "#{message} (chrome_slot retries exhausted after #{CHROME_SLOT_MAX_RETRIES})"
      )
    end
  end

  def self.append_chrome_slot_defer!(result, attempt, wait_elapsed)
    return unless result

    result.append_rpa_step(
      "name" => RPA_STEP_DEFER,
      "description" => "Chrome枠待ち (再キュー #{SeleniumServices::ChromeSlot::DEFER_SECONDS}s)",
      "ok" => nil,
      "at" => Time.current.iso8601,
      "attempt" => attempt,
      "wait_elapsed_sec" => wait_elapsed
    )
  end

  def self.append_chrome_slot_retry!(result, attempt, kind)
    return unless result

    result.append_rpa_step(
      "name" => RPA_STEP_RETRY,
      "description" => "Chrome枠リトライ #{attempt}/#{CHROME_SLOT_MAX_RETRIES} (#{kind})",
      "ok" => false,
      "at" => Time.current.iso8601,
      "attempt" => attempt,
      "error_kind" => kind.to_s,
      "error" => kind.to_s
    )
  end

  def self.reset_result_for_chrome_slot_retry(scenario_id, user_id)
    result = find_result(scenario_id, user_id)
    return unless result

    result.update!(
      result: :running,
      last_step_description: "queued",
      error_kind: nil,
      error_message: nil,
      end_time: nil
    )
  end

  def self.mark_error(scenario_id, user_id, kind, message)
    result = find_result(scenario_id, user_id)
    return unless result

    result.update!(
      result: :error,
      end_time: DateTime.now,
      error_kind: kind,
      error_message: message.to_s.slice(0, 2000)
    )
  end

  def self.find_result(scenario_id, user_id)
    ScenarioUserResponseSeleniumResult.for_visitor(scenario_id, user_id).first
  end

  private

  def find_result(scenario_id, user_id)
    self.class.find_result(scenario_id, user_id)
  end

  def mark_error(scenario_id, user_id, kind, message)
    self.class.mark_error(scenario_id, user_id, kind, message)
  end
end
