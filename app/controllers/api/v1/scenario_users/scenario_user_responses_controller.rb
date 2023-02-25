class Api::V1::ScenarioUsers::ScenarioUserResponsesController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token
  before_action :set_scenario

  def create
    if @client.tamago_repeat?
      scenario_user_response = ScenarioUserResponse.build_record(params)
      scenario_user_response.save
      render json: {code: 1, data: scenario_user_response}
    else
      render json: {code: 1, data: []}
    end
  end

  def create_order
    if @client.tamago_repeat?
      begin
        conversations = @scenario.scenario_user_responses.where(user_input_id: params[:user_id])
        service = TamagoScenario::SeleniumService.new(@scenario, conversations)
        service.process
      rescue StandardError => e

      end
    else
      render json: {code: 1, message: 'not create order'}
    end
  end

  private

  def set_scenario
    @scenario = Scenario.find_by(params[:scenario_id])
    @client = @scenario.chatbot&.user&.client
  end
end
