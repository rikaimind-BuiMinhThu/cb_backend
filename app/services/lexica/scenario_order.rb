module Lexica
  class ScenarioOrder
    def self.sanitize_card_params!(params)
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

    def self.start!(scenario, _client, params)
      return nil if params[:user_id].blank?
      if stored_pan?(scenario, params[:user_id])
        return { json: { code: 2, message: "card data rejected" } }
      end

      lock_name = "lexica_start:#{scenario.id}:#{params[:user_id]}"
      conn = ScenarioUserResponseSeleniumResult.connection
      got_lock = conn.select_value(
        ActiveRecord::Base.sanitize_sql_array(["SELECT GET_LOCK(?, 10)", lock_name])
      ).to_i == 1

      begin
        result = ScenarioUserResponseSeleniumResult
          .for_visitor(scenario.id, params[:user_id])
          .order(id: :desc)
          .first

        if result.present? && !result.retryable?
          return { json: { code: 1, data: result, message: "already started" } }
        end

        attrs = {
          scenario_id: scenario.id,
          chatbot_id: scenario.chatbot_id,
          client_id: scenario.chatbot&.user&.client_id,
          user_input_id: params[:user_id],
          last_step_no: 0,
          last_step_description: "queued",
          start_time: DateTime.now,
          result: :running,
          error_kind: nil,
          error_message: nil
        }
        if result.present?
          result.update!(attrs)
        else
          ScenarioUserResponseSeleniumResult.create!(attrs)
        end

        LexicaScenarioJob.perform_async(params[:scenario_id], params[:user_id])
        {
          json: {
            code: 1,
            message: "queued",
            order_result_mode: scenario.order_result_mode.presence || "wait"
          }
        }
      ensure
        if got_lock
          conn.select_value(
            ActiveRecord::Base.sanitize_sql_array(["SELECT RELEASE_LOCK(?)", lock_name])
          )
        end
      end
    end

    def self.status(scenario, client, params)
      result = ScenarioUserResponseSeleniumResult
        .for_visitor(params[:scenario_id] || scenario&.id, params[:user_id])
        .order(id: :desc)
        .first
      return { json: { code: 2, message: "not found" } } if result.blank?

      slot = SeleniumServices::ChromeSlot.new(client) if client&.lexica?
      {
        json: {
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
      }
    end

    def self.token_failure(scenario, client, params)
      return { json: { code: 2, message: "not lexica" } } unless client&.lexica?

      result = ScenarioUserResponseSeleniumResult.for_visitor(scenario.id, params[:user_id]).first_or_initialize
      result.assign_attributes(
        scenario_id: scenario.id,
        chatbot_id: scenario.chatbot_id,
        client_id: scenario.chatbot&.user&.client_id,
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
      { json: { code: 1, data: { id: result.id } } }
    end

    def self.zeus_config(scenario, client)
      return { json: { code: 2, message: "not lexica" } } unless client&.lexica?

      gateway = PaymentGateway.zeus.find_by(user_id: scenario.chatbot&.user_id)
      return { json: { code: 2, message: "zeus not configured" } } if gateway.blank?

      {
        json: {
          code: 1,
          data: {
            token_js_url: gateway.token_js_url,
            client_ip: gateway.client_ip,
            ipcode: gateway.ipcode,
            mode: gateway.mode
          }
        }
      }
    end

    def self.stored_pan?(scenario, user_id)
      raw = scenario.scenario_user_responses.where(user_input_id: user_id, data_input_name: "credit_card_payment").last&.value
      Lexica::CardPayload.contains_pan?(raw)
    end
    private_class_method :stored_pan?
  end
end
