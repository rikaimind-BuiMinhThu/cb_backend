class Api::V1::ScenarioUsers::ConversationsController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  def create
    Order.create!(order_params.merge({client_id: client_id}))
    render json: { message: 'Order created successfully' }, status: :ok
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error "An error occurred: #{e.message}"
    render json: { message: e.message }, status: :internal_server_error
  end

  private

  def client_id
    scenario = Scenario.find_by(id: params[:scenario_id])
    chatbot = Chatbot.find_by(id: params[:bot_id])
    scenario&.chatbot&.user&.client_id
  end

  # Only allow required fields
  def order_params
    params.require(:scenario_id)
    params.require(:bot_type)
    params.require(:user_input_id)
  end
end
