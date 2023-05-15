class EcForceJob
  
  include Sidekiq::Worker
  
  def perform(scenario_id, user_id)
    begin
      scenario = Scenario.find(scenario_id)
      client = scenario.chatbot&.user&.client
      conversations = scenario.scenario_user_responses.where(user_input_id: user_id)
      service = SeleniumServices::EcForce.new(scenario, conversations)
      byebug
      service.process
      if service.is_error
        # TBD
      end
    rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError => e
      # TBD
    end
  end
end
