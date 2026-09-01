class Api::V1::ScenarioUsers::ScenarioUserResponsesController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token
  before_action :set_scenario

  def create
    if !!@client && params[:user_id].present?
      sanitize_lexica_card_params! if @client.lexica?
      scenario_user_responses = ScenarioUserResponse.build_record(params)
      scenario_user_responses.each(&:save!) if scenario_user_responses.present?
      render json: { code: 1, data: scenario_user_responses }
    else
      render json: { code: 0, data: [] }
    end
  end

  def create_order
    if params[:user_id].present?
      selenium_result = ScenarioUserResponseSeleniumResult.find_by(user_input_id: params[:user_id], scenario_id: @scenario.id)
      if selenium_result.present?
        if @client&.lexica?
          return render json: { code: 1, data: selenium_result, message: "already started" } unless selenium_result.retryable?
        else
          return
        end
      end
      if @client&.lexica? && lexica_stored_pan?(params[:user_id])
        return render json: { code: 2, message: "card data rejected" }
      end
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
      if selenium_result.present?
        selenium_result.update!(attrs.merge(error_kind: nil, error_message: nil, last_step_description: @client&.lexica? ? "queued" : attrs[:last_step_description]))
      else
        create_attrs = @client&.lexica? ? attrs.merge(last_step_description: "queued") : attrs
        ScenarioUserResponseSeleniumResult.create!(create_attrs)
      end
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
      elsif @client&.lexica?
        LexicaScenarioJob.perform_async(params[:scenario_id], params[:user_id])
        render json: { code: 1, message: "queued", order_result_mode: @scenario.order_result_mode.presence || "wait" }
      else
        render json: { code: 1, message: "not create order" }
      end
    end
  end

  def selenium_results
    result = ScenarioUserResponseSeleniumResult.find_by(user_input_id: params[:user_id], scenario_id: params[:scenario_id])
    return render json: { code: 2, message: "not found" } if result.blank?

    slot = SeleniumServices::ChromeSlot.new(@client) if @client&.lexica?
    render json: {
      code: 1,
      data: {
        id: result.id,
        result: result.result,
        last_step_description: result.last_step_description,
        error_kind: result.error_kind,
        error_message: result.error_message,
        queued: result.running? && result.last_step_description.to_s == "queued",
        busy: slot&.queued?
      }
    }
  end

  def token_failures
    return render json: { code: 2, message: "not lexica" } unless @client&.lexica?

    result = ScenarioUserResponseSeleniumResult.find_or_initialize_by(
      user_input_id: params[:user_id],
      scenario_id: @scenario.id
    )
    result.assign_attributes(
      scenario_id: @scenario.id,
      chatbot_id: @scenario.chatbot_id,
      client_id: @scenario.chatbot&.user&.client_id,
      last_step_no: 0,
      last_step_description: "token_failure",
      start_time: DateTime.now,
      end_time: DateTime.now,
      result: :error,
      error_kind: "token_failure",
      error_message: params[:message].presence || "card token failed",
      masked_pan: params[:masked_pan],
      path: params[:path],
      payment: "credit"
    )
    result.save!
    render json: { code: 1, data: { id: result.id } }
  end

  def zeus_config
    return render json: { code: 2, message: "not lexica" } unless @client&.lexica?

    gateway = PaymentGateway.zeus.find_by(user_id: @scenario.chatbot&.user_id)
    return render json: { code: 2, message: "zeus not configured" } if gateway.blank?

    render json: {
      code: 1,
      data: {
        token_js_url: gateway.token_js_url,
        client_ip: gateway.client_ip,
        ipcode: gateway.ipcode,
        mode: gateway.mode
      }
    }
  end

  private

  def set_scenario
    @scenario = Scenario.find_by_id(params[:scenario_id])
    @client = @scenario.chatbot&.user&.client
  end

  def lexica_payload_has_pan?
    contents = params.dig(:message, :message_content) || []
    contents.any? do |content|
      card = content[:card_payment_radio_button] || content["card_payment_radio_button"] ||
        content[:credit_card_payment] || content["credit_card_payment"]
      next false if card.blank?

      number = card.dig(:card_number) || card.dig("card_number") || card.dig(:number) || card["number"]
      cvc = card.dig(:cvc) || card["cvc"] || card.dig(:security_code) || card["security_code"]
      Lexica::CardPayload.contains_pan?(number) || cvc.to_s.match?(/\A\d{3,4}\z/)
    end
  end

  def sanitize_lexica_card_params!
    contents = params.dig(:message, :message_content) || []
    contents.each do |content|
      card = content[:card_payment_radio_button] || content["card_payment_radio_button"] ||
        content[:credit_card_payment] || content["credit_card_payment"]
      next if card.blank?
      next if card[:token_key].present? || card["token_key"].present?

      number = (card[:card_number] || card["card_number"] || card[:number] || card["number"]).to_s
      last4 = number.gsub(/\D/, "")[-4, 4]
      card[:card_number] = last4.present? ? "************#{last4}" : nil
      card["card_number"] = card[:card_number]
      %w[card_number1 card_number2 card_number3 card_number4 cvc security_code number].each do |key|
        card[key] = nil
        card[key.to_sym] = nil
      end
    end
  end

  def lexica_stored_pan?(user_id)
    raw = @scenario.scenario_user_responses.where(user_input_id: user_id, data_input_name: "credit_card_payment").last&.value
    Lexica::CardPayload.contains_pan?(raw)
  end
end
