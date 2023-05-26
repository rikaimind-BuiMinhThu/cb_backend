class Api::V1::ScenarioUsers::ScenarioUserResponsesController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token
  before_action :set_scenario

  def create
    if (@client.tamago_repeat? || @client.shopify? || @client.subsc_store? || @client.ec_force?) && params[:user_id].present?
      scenario_user_responses = ScenarioUserResponse.build_record(params)
      scenario_user_responses.each(&:save!) if scenario_user_responses.present?
      render json: { code: 1, data: scenario_user_responses }
    else
      render json: { code: 0, data: [] }
    end
  end

  def update
    if (@client.tamago_repeat? || @client.shopify? || @client.subsc_store? || @client.ec_force?) && params[:user_id].present?
      conversations = @scenario.scenario_user_responses.where(user_input_id: params[:user_id])
      scenario_user_responses = ScenarioUserResponse.build_record(params)
      conversations.each do |conversation|
        scenario_user_responses.each do |scenario_user_response|
          if conversation[:data_input_name] == scenario_user_response[:data_input_name]
            conversation.update(id:conversation[:id],  user_input_id:scenario_user_response[:user_input_id], string_value: scenario_user_response[:string_value],boolean_value: scenario_user_response[:boolean_value], integer_value:scenario_user_response[:integer_value], data_input_name: scenario_user_response[:data_input_name], created_at:conversation[:created_at], text_value:scenario_user_response[:text_value])
            render json: { code: 1, data: scenario_user_responses }
          end
        end
      end
    else
      render json: { code: 0, data: [] }
    end
  end
  
      


  def create_order
    if @client.tamago_repeat? && params[:user_id].present?
      TamagoScenarioJob.perform_async(params[:scenario_id], params[:user_id])
    elsif @client.subsc_store? && params[:user_id].present?
      SubscStoreJob.perform_async(params[:scenario_id], params[:user_id])
    elsif @client.shopify? && params[:user_id].present?
      scenario_id = params[:scenario_id]
      user_id = params[:user_id]
      ShopifyJob.perform_async(params[:scenario_id], params[:user_id])
    elsif @client.ec_force? && params[:user_id].present?
      scenario_id = params[:scenario_id]
      user_id = params[:user_id]
      # scenario = Scenario.find(scenario_id)
      # conversations = scenario.scenario_user_responses.where(user_input_id: user_id)
      # service = SeleniumServices::EcForce.new(scenario, conversations )
      # service.process
      EcForceJob.perform_async(params[:scenario_id], params[:user_id])
      
    else
      render json: { code: 1, message: "not create order" }
    end
  end

  private
  def self.get_selected_obj_for_card_payment_radio_button(conversation)
    selected_value = conversation[:card_payment_radio_button][:initial_selection]
    conversation[:card_payment_radio_button][:radio_contents].detect { |obj| obj[:value] == selected_value }
  end

  def set_scenario
    @scenario = Scenario.find_by_id(params[:scenario_id])
    @client = @scenario.chatbot&.user&.client
  end
end
