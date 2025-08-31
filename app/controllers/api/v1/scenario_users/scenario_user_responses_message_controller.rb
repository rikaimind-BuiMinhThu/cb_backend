class Api::V1::ScenarioUsers::ScenarioUserResponsesMessageController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token
  before_action :set_scenario

  rescue_from ActionController::ParameterMissing, with: :handle_missing_param
  
  def create
    msgs = params[:msgs] || []
    scenario_id = params[:scenario_id]
    user_id     = params[:user_id]

    records = msgs.map do |msg|
      ScenarioUserResponseMessage.new(
        scenario_id: scenario_id,
        user_id: user_id,
        message_id: msg[:id],
        submit_type: msg[:type]
      )
    end

    if records.all?(&:valid?)
      records.each(&:save)
      render json: { code: 1, data: records }, status: :created
    else
      errors = records.map { |r| r.errors.full_messages }.flatten
      render json: { code: 2, message: "Save failed", errors: errors }, status: :unprocessable_entity
    end
  end

  private

  def response_params
    params.require(:scenario_id)
    params.require(:user_id)
    params.permit(:scenario_id, :user_id, msgs: [:id, :type])
  end

  def handle_missing_param(exception)
    render json: { code: 2, message: "Missing parameter: #{exception.param}" }, status: :bad_request
  end

  def set_scenario
    @scenario = Scenario.find_by_id(params[:scenario_id])
    @client = @scenario.chatbot&.user&.client
  end
end