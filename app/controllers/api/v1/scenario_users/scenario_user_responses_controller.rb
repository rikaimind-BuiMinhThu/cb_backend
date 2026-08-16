class Api::V1::ScenarioUsers::ScenarioUserResponsesController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token
  before_action :set_scenario

  def create
    if !!@client && params[:user_id].present?
      scenario_user_responses = ScenarioUserResponse.build_record(params)
      scenario_user_responses.each(&:save!) if scenario_user_responses.present?
      render json: { code: 1, data: scenario_user_responses }
    else
      render json: { code: 0, data: [] }
    end
  end

  def create_order
    unless params[:user_id].present?
      return render json: { code: 0, message: "user_id is required" }
    end

    execution_mode = OrderExecutionMode.resolve(@client, @scenario)
    if @client&.subsc_store? && execution_mode == :fukushashiki_only
      return render json: { code: 1, execution_mode: execution_mode, message: "skip automation" }
    end
    if @client&.subsc_store? && execution_mode == :api_only && !@client.subsc_store_api_ready?
      return render json: { code: 2, message: "サブスクストア API の Shop URL / Client ID / Client Secret を設定してください" }, status: :unprocessable_entity
    end

    selenium_result = ScenarioUserResponseSeleniumResult.find_by(user_input_id: params[:user_id])
    if selenium_result.present?
      if @client&.subsc_store? && execution_mode == :api_only && selenium_result.error?
        selenium_result.destroy
        Order.where(scenario_id: @scenario.id, user_input_id: params[:user_id]).delete_all
      else
        return render json: { code: 1, message: "already started" }
      end
    end

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
      if @client.ec_force?
        bot_type = 'web'
      end
      Order.create(
        client_id: @scenario.chatbot&.user&.client_id,
        scenario_id: @scenario.id,
        user_input_id: params[:user_id],
        bot_type: bot_type,
      )
      if @client.tamago_repeat?
        TamagoScenarioJob.perform_async(params[:scenario_id], params[:user_id])
      elsif @client.subsc_store?
        dispatch_subsc_store_order(execution_mode)
      elsif @client.shopify?
        ShopifyJob.perform_async(params[:scenario_id], params[:user_id])
      elsif @client.ec_force?
        EcForceJob.perform_async(params[:scenario_id], params[:user_id])
      elsif @client.repeat_plus?
        RepeatPlusJob.perform_async(params[:scenario_id], params[:user_id])
      end
      order = Order.find_by(scenario_id: @scenario.id, user_input_id: params[:user_id])
      render json: {
        code: 1,
        execution_mode: execution_mode,
        upsell_available: @client.subsc_store? && execution_mode == :api_only && @scenario.upsell_available?,
        external_order_id: order&.external_order_id
      }
    else
      render json: { code: 1, message: "not create order" }
    end
  rescue SubscStore::Error => e
    render json: { code: 2, message: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { code: 2, message: e.message }, status: :unprocessable_entity
  end

  def confirm_order
    unless params[:user_id].present?
      return render json: { code: 0, message: "user_id is required" }
    end
    unless @client&.subsc_store?
      return render json: { code: 2, message: "confirm_order is only for subsc_store" }, status: :unprocessable_entity
    end
    if OrderExecutionMode.resolve(@client, @scenario) != :api_only
      return render json: { code: 2, message: "confirm_order is only for API mode" }, status: :unprocessable_entity
    end
    unless @client.subsc_store_api_ready?
      return render json: { code: 2, message: "サブスクストア API の Shop URL / Client ID / Client Secret を設定してください" }, status: :unprocessable_entity
    end

    purchase, payload = build_subsc_store_purchase
    result = purchase.confirm(payload)
    mapper = SubscStore::ConfirmDisplayMapper.new(
      confirm_result: result,
      payload: payload,
      scenario: @scenario,
      payment_config: purchase.payment_config
    )
    unless mapper.success?
      return render json: {
        code: 2,
        success: false,
        message: mapper.error_message.presence || "注文内容を確認できませんでした",
        errors: result["errors"],
        display: mapper.build
      }, status: :unprocessable_entity
    end

    render json: { code: 1, success: true, display: mapper.build }
  rescue SubscStore::Error => e
    body = e.body.is_a?(Hash) ? e.body : {}
    mapper = SubscStore::ConfirmDisplayMapper.new(
      confirm_result: body,
      payload: defined?(payload) ? payload : {},
      scenario: @scenario,
      payment_config: nil
    )
    render json: {
      code: 2,
      success: false,
      message: mapper.error_message.presence || e.message,
      display: mapper.build
    }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { code: 2, success: false, message: e.message }, status: :unprocessable_entity
  end

  def change_order_items
    unless params[:user_id].present?
      return render json: { code: 0, message: "user_id is required" }
    end
    unless @client&.subsc_store?
      return render json: { code: 2, message: "change_order_items is only for subsc_store" }, status: :unprocessable_entity
    end

    order = Order.find_by(scenario_id: @scenario.id, user_input_id: params[:user_id])
    if order&.external_order_id.blank?
      return render json: { code: 2, message: "external order id is missing" }, status: :unprocessable_entity
    end

    quantity = @scenario.scenario_user_responses.find_by(user_input_id: params[:user_id], data_input_name: "quantity")&.value
    changer = SubscStore::OrderChange.new(@client)
    payload = changer.build_payload(@scenario, quantity: (quantity.presence || 1).to_i)
    result = changer.confirm_and_execute(order.external_order_id, payload)
    render json: { code: 1, data: result }
  rescue SubscStore::Error => e
    render json: { code: 2, message: e.message, body: e.body }, status: :unprocessable_entity
  end

  def payment_config
    unless @client&.subsc_store_api_ready?
      return render json: { code: 2, message: "SubscStore API credentials are missing" }, status: :unprocessable_entity
    end

    config = SubscStore::PaymentConfig.new(SubscStore::HttpClient.new(@client)).public_tokenize_config
    render json: { code: 1, data: config }
  rescue SubscStore::Error => e
    render json: { code: 2, message: e.message }, status: :unprocessable_entity
  end

  private

  def dispatch_subsc_store_order(execution_mode)
    if execution_mode == :api_only
      SubscStoreApiJob.new.perform(params[:scenario_id], params[:user_id], credit_card_params)
    else
      SubscStoreJob.perform_async(params[:scenario_id], params[:user_id])
    end
  end

  def build_subsc_store_purchase
    conversations = @scenario.scenario_user_responses.where(user_input_id: params[:user_id])
    purchase = SubscStore::Purchase.new(@client)
    payload = SubscStore::OrderPayloadBuilder.new(
      @scenario,
      conversations,
      credit_card: credit_card_params,
      payment_config: purchase.payment_config
    ).build
    [purchase, payload]
  end

  def credit_card_params
    raw = params[:credit_card] || params[:credit_card_token] || {}
    raw = raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)
    raw = {} unless raw.is_a?(Hash)
    raw.stringify_keys.slice("token_key", "masked_card_number", "brand", "expire_month", "expire_year", "holder_name")
  end

  def set_scenario
    @scenario = Scenario.find_by_id(params[:scenario_id])
    return render json: { code: 2, message: "Scenario not found" } if @scenario.blank?

    @client = @scenario.chatbot&.user&.client
  end
end
