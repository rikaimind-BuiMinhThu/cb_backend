class Api::V1::ScenarioUsers::ConversionsController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  def create
    Order.create!(order_params.merge({client_id: client_id}))
    render json: { message: 'Order created successfully' }, status: :ok
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error "An error occurred: #{e.message}"
    render json: { message: e.message }, status: :internal_server_error
  end

  private

  def client_id
    scenario = Scenario.find_by(id: params[:scenario_id])
    raise ActiveRecord::RecordNotFound, "Invalid scenario id" unless scenario&.chatbot&.user&.client_id
    scenario&.chatbot&.user&.client_id
  end

  def order_params
    scenario_id = params.require(:scenario_id)
    bot_type = params.require(:bot_type)
    user_input_id = params.require(:user_input_id)

    {
      scenario_id: scenario_id,
      bot_type: bot_type,
      user_input_id: user_input_id
    }
  end
end
