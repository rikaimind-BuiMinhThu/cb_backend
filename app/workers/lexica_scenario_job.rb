class LexicaScenarioJob
  include Sidekiq::Worker
  sidekiq_options queue: :lexica, retry: 0

  def perform(scenario_id, user_id)
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
    slot = SeleniumServices::ChromeSlot.new(client)
    result&.update!(last_step_description: slot.queued? ? "queued" : "running")

    slot.with_slot do
      result&.update!(last_step_description: "running")
      service = SeleniumServices::Lexica.build(scenario, conversations)
      service.process
    end
  rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError => e
    mark_error(scenario_id, user_id, "alert", e.message)
  rescue Timeout::Error => e
    mark_error(scenario_id, user_id, "chrome_slot_timeout", e.message)
  rescue => e
    mark_error(scenario_id, user_id, "rpa_error", e.message)
  end

  private

  def find_result(scenario_id, user_id)
    ScenarioUserResponseSeleniumResult.find_by(user_input_id: user_id, scenario_id: scenario_id)
  end

  def mark_error(scenario_id, user_id, kind, message)
    result = find_result(scenario_id, user_id)
    return unless result

    result.update!(
      result: :error,
      end_time: DateTime.now,
      error_kind: kind,
      error_message: message.to_s.slice(0, 2000)
    )
  end
end
