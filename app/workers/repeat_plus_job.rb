class RepeatPlusJob
  include Sidekiq::Worker

  def perform(scenario_id, user_id)
    begin
      scenario = Scenario.find(scenario_id)
      conversations = scenario.scenario_user_responses.where(user_input_id: user_id)
      service = SeleniumServices::RepeatPlus.new(scenario, conversations)
      service.process
      if service.is_error
        # TBD
      end
    rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError => e
      # TBD
    end
  end
end
