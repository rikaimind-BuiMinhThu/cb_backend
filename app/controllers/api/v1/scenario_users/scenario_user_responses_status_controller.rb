class Api::V1::ScenarioUsers::ScenarioUserResponsesStatusController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token
  before_action :set_scenario

  rescue_from ActionController::ParameterMissing, with: :handle_missing_param
  
  def save_status
    response = ScenarioUserResponseStatus.find_or_initialize_by(
      scenario_id: response_params[:scenario_id],
      user_input_id: response_params[:user_input_id]
    )

    response.status = response_params[:status].to_s

    if response.save
      render json: { code: 1, data: response }
    else
      render json: { code: 2, message: "Save failed", errors: response.errors.full_messages }
    end
  end

  private

  def response_params
    params.require(:scenario_id)
    params.require(:user_input_id)
    params.require(:status)
    params.permit(:scenario_id, :user_input_id, :status)
  end

  def handle_missing_param(exception)
    render json: { code: 2, message: "Missing parameter: #{exception.param}" }, status: :bad_request
  end

  def set_scenario
    @scenario = Scenario.find_by_id(params[:scenario_id])
    @client = @scenario.chatbot&.user&.client
  end
end