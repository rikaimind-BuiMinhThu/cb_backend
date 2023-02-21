class Api::V1::ScenarioUsers::ScenarioUserResponsesController < ApplicationController
  def create
    scenario = Scenario.find_by(user_response_params[:scenario_id])
    scenario_user_response = ScenarioUserResponse.create(
      message_bag_params.merge({ data_input_name: scenario.data_input_name })
    )
    render json: {code: 1, data: scenario_user_response}
  end

  private

  def user_response_params
    params.require(:user_response).permit(:scenario_id, :value)
  end
end
