class Api::V1::ScenarioUsers::ScenarioUserResponsesController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  def create
    scenario_user_response = ScenarioUserResponse.build_record(params)
    scenario_user_response.save
    render json: {code: 1, data: scenario_user_response}
  end

  def create_order
    scenario = Scenario.find_by(params[:scenario_id])
    conversations = scenario.scenario_user_responses.where(user_input_id: params[:user_id])
    service = TamagoScenario::SeleniumService.new(scenario, conversations)
    service.process
  end
end
