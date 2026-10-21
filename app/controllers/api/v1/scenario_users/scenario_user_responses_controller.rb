class Api::V1::ScenarioUsers::ScenarioUserResponsesController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token
  before_action :set_scenario

  def create
    if !!@client && params[:user_id].present?
      Lexica::ScenarioOrder.sanitize_card_params!(params) if @client.lexica?
      scenario_user_responses = ScenarioUserResponse.build_record(params)
      scenario_user_responses.each(&:save!) if scenario_user_responses.present?
      render json: { code: 1, data: scenario_user_responses }
    else
      render json: { code: 0, data: [] }
    end
  end

  def create_order
    if @client&.lexica?
      payload = Lexica::ScenarioOrder.start!(@scenario, @client, params)
      return if payload.nil?

      return render payload
    end

    if params[:user_id].present?
      selenium_result = ScenarioUserResponseSeleniumResult.for_visitor(@scenario.id, params[:user_id]).first
      return if selenium_result.present?

      attrs = {
        scenario_id: @scenario.id,
        chatbot_id: @scenario.chatbot_id,
        client_id: @scenario.chatbot&.user&.client_id,
        user_input_id: params[:user_id],
        last_step_no: 0,
        last_step_description: "",
        start_time: DateTime.now,
        result: :running,
      }
      ScenarioUserResponseSeleniumResult.create!(attrs)
      bot_type = params[:bot_type]
      if @client.tamago_repeat? || @client.subsc_store? || @client.shopify? || @client.ec_force? || @client.repeat_plus?
        if @client.tamago_repeat?
          TamagoScenarioJob.perform_async(params[:scenario_id], params[:user_id])
        elsif @client.subsc_store?
          SubscStoreJob.perform_async(params[:scenario_id], params[:user_id])
        elsif @client.shopify?
          ShopifyJob.perform_async(params[:scenario_id], params[:user_id])
        elsif @client.ec_force?
          EcForceJob.perform_async(params[:scenario_id], params[:user_id])
          bot_type = 'web'
        elsif @client.repeat_plus?
          RepeatPlusJob.perform_async(params[:scenario_id], params[:user_id])
        end
        Order.create(
          client_id: @scenario.chatbot&.user&.client_id,
          scenario_id: @scenario.id,
          user_input_id: params[:user_id],
          bot_type: bot_type,
        )
      else
        render json: { code: 1, message: "not create order" }
      end
    end
  end

  def selenium_results
    render Lexica::ScenarioOrder.status(@scenario, @client, params)
  end

  def token_failures
    render Lexica::ScenarioOrder.token_failure(@scenario, @client, params)
  end

  def zeus_config
    render Lexica::ScenarioOrder.zeus_config(@scenario, @client)
  end

  private

  def set_scenario
    @scenario = Scenario.find_by_id(params[:scenario_id])
    @client = @scenario.chatbot&.user&.client
  end
end
