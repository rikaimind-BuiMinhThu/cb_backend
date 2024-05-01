class Api::V1::ScenarioUsers::ScenarioUserResponsesController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token
  before_action :set_scenario

  def create
    if !!@client && (@client.tamago_repeat? || @client.shopify? || @client.subsc_store? || @client.repeat_plus?) && params[:user_id].present?
      scenario_user_responses = ScenarioUserResponse.build_record(params)
      scenario_user_responses.each(&:save!) if scenario_user_responses.present?
      if @client.shopify? && scenario_user_responses.present?
        return render json: { code: 1, data: scenario_user_responses, message: 'controller' }
      end
      render json: { code: 1, data: scenario_user_responses }
    elsif !!@client && (@client.ec_force?) && params[:user_id].present?
      scenario_user_responses = ScenarioUserResponse.build_record(params)
      scenario_user_responses.each(&:save!) if scenario_user_responses.present?
      render json: { code: 1, data: scenario_user_responses }
    else
      render json: { code: 0, data: [] }
    end
  end

  def create_order
    if params[:user_id].present?
      selenium_result = ScenarioUserResponseSeleniumResult.find_by(user_input_id: params[:user_id])
      return if selenium_result.present?
      ScenarioUserResponseSeleniumResult.create(
        scenario_id: @scenario.id,
        chatbot_id: @scenario.chatbot_id,
        client_id: @scenario.chatbot&.user&.client_id,
        user_input_id: params[:user_id],
        last_step_no: 0,
        last_step_description: "",
        start_time: DateTime.now,
        result: :running,
      )
      bot_type = params[:bot_type]
      if @client.tamago_repeat? || @client.subsc_store? || @client.shopify? || @client.ec_force? || @client.repeat_plus?
        if @client.tamago_repeat?
          TamagoScenarioJob.perform_async(params[:scenario_id], params[:user_id])
        elsif @client.subsc_store?
          SubscStoreJob.perform_async(params[:scenario_id], params[:user_id])
        elsif @client.shopify?
          scenario_id = params[:scenario_id]
          user_id = params[:user_id]
          ShopifyJob.perform_async(params[:scenario_id], params[:user_id])
        elsif @client.ec_force?
          scenario_id = params[:scenario_id]
          user_id = params[:user_id]
          # scenario = Scenario.find(scenario_id)
          # conversations = scenario.scenario_user_responses.where(user_input_id: user_id)
          # service = SeleniumServices::EcForce.new(scenario, conversations )
          # service.process
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

  private

  def set_scenario
    @scenario = Scenario.find_by_id(params[:scenario_id])
    @client = @scenario.chatbot&.user&.client
  end
end
