class Api::V1::ScenarioUsers::ScenarioUserResponsesController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token
  before_action :set_scenario

  def create
    if @client.tamago_repeat?
      scenario_user_response = ScenarioUserResponse.build_record(params)
      scenario_user_response.save! if scenario_user_response.present?
      render json: {code: 1, data: scenario_user_response}
    else
      render json: {code: 1, data: []}
    end
  end

  def create_order
    if @client.tamago_repeat?
      begin
        conversations = @scenario.scenario_user_responses.where(user_input_id: params[:user_id])
        user_email = conversations.find_by(data_input_name: 'user_email').value
        data = {
          shop_name: @client.name,
          user_email: user_email
        }
        service = TamagoScenario::SeleniumService.new(@scenario, conversations)
        service.process
        if !service.status
          OrderFailedMailer.send_email(user_email, @client.email, data).deliver_later
        end
      rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError => e
        OrderFailedMailer.send_email(user_email, @client.email, data).deliver_later
      end
    else
      render json: {code: 1, message: 'not create order'}
    end
  end

  private

  def set_scenario
    @scenario = Scenario.find_by_id(params[:scenario_id])
    @client = @scenario.chatbot&.user&.client
  end
end
