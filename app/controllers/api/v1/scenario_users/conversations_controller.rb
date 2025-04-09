class Api::V1::ScenarioUsers::ConversationsController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  def create
    params_to_check = %i[scenario_id client_id bot_type user_input_id]

    params_to_check.each do |param|
      render json: { code: 2, message: "#{param} is required!" } and return if params[param].to_s.strip.empty?

      begin
        @order = Order.create!(
          scenario_id: params[:scenario_id],
          bot_type: params[:bot_type],
          client_id: params[:client_id],
          user_input_id: params[:user_input_id]
        )

        render json: { code: 1, message: 'Order created successfully' }
      rescue StandardError => e
        render json: { code: 2, message: e.message }

        Rails.logger.error "An error occurred: #{e.message}"
      end
    end
  end
end
