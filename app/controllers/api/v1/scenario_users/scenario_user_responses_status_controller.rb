class Api::V1::ScenarioUsers::ScenarioUserResponsesStatusController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token
  before_action :set_scenario

  rescue_from ActionController::ParameterMissing, with: :handle_missing_param
  
  def create
    exist_record = ScenarioUserResponseStatus.find_by(
      scenario_id: response_params[:scenario_id],
      user_input_id: response_params[:user_input_id]
    )
    
    if exist_record.present?
      render json: { code: 1, data: exist_record }, status: :ok
      return
    end

    status_record = ScenarioUserResponseStatus.new(response_params)

    if status_record.save
      render json: { code: 1, data: status_record }, status: :created
    else
      render json: { code: 2, message: "Save failed", errors: response.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    status_record = ScenarioUserResponseStatus.find_by(
      scenario_id: response_params[:scenario_id],
      user_input_id: response_params[:user_input_id]
    )

    if status_record.nil?
      render json: { code: 2, message: "Record not found" }, status: :not_found
      return
    end

    if status_record.update(status: response_params[:status])
      render json: { code: 1, data: status_record }, status: :ok
    else
      render json: { code: 2, message: "Update failed", errors: status_record.errors.full_messages }, status: :unprocessable_entity
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