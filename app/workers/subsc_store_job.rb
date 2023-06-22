class SubscStoreJob
  include Sidekiq::Worker

  def perform(scenario_id, user_id)
    begin
      scenario = Scenario.find(scenario_id)
      client = scenario.chatbot&.user&.client
      conversations = scenario.scenario_user_responses.where(user_input_id: user_id)
      service = SeleniumServices::SubscStore.new(scenario, conversations)
      service.process
    rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError => e
    end
  end
end
