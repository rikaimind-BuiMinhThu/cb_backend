class TamagoScenarioJob
  include Sidekiq::Worker

  def perform(scenario_id, user_id)
    begin
      scenario = Scenario.find(scenario_id)
      client = scenario.chatbot&.user&.client
      conversations = scenario.scenario_user_responses.where(user_input_id: user_id)
      user_email = conversations.find_by(data_input_name: 'user_email').value
      data = {
        shop_name: client.name,
        user_email: user_email
      }

      service = SeleniumServices::TamagoRepeat.new(scenario, conversations)
      service.process
      if service.is_error
        # OrderFailedMailer.send_email(user_email, client.email, data).deliver_later
      end
    rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError => e
      # OrderFailedMailer.send_email(user_email, client.email, data).deliver_later
    end
  end
end
