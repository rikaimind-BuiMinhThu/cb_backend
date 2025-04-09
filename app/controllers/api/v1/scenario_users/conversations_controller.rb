class Api::V1::ScenarioUsers::ConversationsController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  def create
    permitted = order_params

    # Validate presence of required parameters
    required_params = %i[scenario_id bot_type client_id user_input_id]
    missing_params = required_params.select { |param| permitted[param].blank? }

    if missing_params.any?
      return render json: { message: "#{missing_params.join(', ')} #{missing_params.size > 1 ? 'are' : 'is'} required!" },
                    status: :bad_request
    end

    # Create Order with the permitted parameters
    @order = Order.create!(permitted)
    render json: { message: 'Order created successfully' }, status: :ok
  rescue StandardError => e
    Rails.logger.error "An error occurred: #{e.message}"
    render json: { message: e.message }, status: :internal_server_error
  end

  private

  # Only allow required fields
  def order_params
    params.permit(:scenario_id, :bot_type, :client_id, :user_input_id)
  end
end
