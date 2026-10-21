class Api::V1::ScenarioUsers::ScenarioUsersController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token
  before_action :set_scenario

  rescue_from ActionController::ParameterMissing, with: :handle_missing_param
  
  def entry
    scenario_user = ScenarioUser.find_or_create_by!(
      scenario_id: response_params[:scenario_id],
      user_input_id: response_params[:user_id]
    )

    scenario_user.increment!(:entry_count)

    render json: { code: 1, data: scenario_user }, status: :ok
  end

  def tracking
    scenario_user = ScenarioUser.find_or_create_by!(
      scenario_id: tracking_params[:scenario_id],
      user_input_id: tracking_params[:user_id]
    )
    scenario_user.update!(tracking_attributes)
    render json: { code: 1, data: scenario_user }, status: :ok
  end

  private

  def tracking_attributes
    {
      device: tracking_params[:device],
      browser: tracking_params[:browser],
      country: tracking_params[:country],
      city: tracking_params[:city],
      referer: tracking_params[:referer],
      page_url: tracking_params[:page_url],
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
    }.compact_blank
  end

  def tracking_params
    params.require(:scenario_id)
    params.require(:user_id)
    params.permit(
      :scenario_id,
      :user_id,
      :device,
      :browser,
      :country,
      :city,
      :referer,
      :page_url
    )
  end

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
    @client = @scenario&.chatbot&.user&.client
  end
end
