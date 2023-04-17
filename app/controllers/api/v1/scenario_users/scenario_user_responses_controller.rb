class Api::V1::ScenarioUsers::ScenarioUserResponsesController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token
  before_action :set_scenario

  def create
    if (@client.tamago_repeat? || @client.shopify?) && params[:user_id].present?
      scenario_user_responses = ScenarioUserResponse.build_record(params)
      scenario_user_responses.each(&:save!) if scenario_user_responses.present?
      render json: { code: 1, data: scenario_user_responses }
    else
      render json: { code: 0, data: [] }
    end
  end

  def create_order
    if @client.tamago_repeat? && params[:user_id].present?
      TamagoScenarioJob.perform_async(params[:scenario_id], params[:user_id])
    elsif @client.shopify? && params[:user_id].present?
      scenario_id = params[:scenario_id]
      user_id = params[:user_id]
      ShopifyJob.perform_async(params[:scenario_id], params[:user_id])
    else
      render json: { code: 1, message: "not create order" }
    end
  end

  private

  def set_scenario
    @scenario = Scenario.find_by_id(params[:scenario_id])
    @client = @scenario.chatbot&.user&.client
  end
end
