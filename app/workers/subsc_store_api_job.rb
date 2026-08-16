class SubscStoreApiJob
  include Sidekiq::Worker

  def perform(scenario_id, user_id, credit_card = {})
    selenium_result = nil
    scenario = Scenario.find(scenario_id)
    client = scenario.chatbot&.user&.client
    conversations = scenario.scenario_user_responses.where(user_input_id: user_id)
    selenium_result = ScenarioUserResponseSeleniumResult.find_by(user_input_id: user_id)

    raise SubscStore::Error, "Client is missing" if client.blank?
    raise SubscStore::Error, "SubscStore API credentials are missing" unless client.subsc_store_api_ready?

    purchase = SubscStore::Purchase.new(client)
    payload = SubscStore::OrderPayloadBuilder.new(
      scenario,
      conversations,
      credit_card: normalize_credit_card(credit_card),
      payment_config: purchase.payment_config
    ).build

    create_result = purchase.create(payload)
    if create_result["success"] == false
      mapper = SubscStore::ConfirmDisplayMapper.new(
        confirm_result: create_result,
        payload: payload,
        scenario: scenario,
        payment_config: purchase.payment_config
      )
      raise SubscStore::Error.new(mapper.error_message.presence || "注文を作成できませんでした", body: create_result)
    end
    meta = purchase.created_order_meta(create_result)
    order = Order.find_by(scenario_id: scenario.id, user_input_id: user_id)
    order&.update!(
      external_order_id: meta[:order_id].to_s.presence,
      external_order_uid: meta[:order_uid].to_s.presence
    )
    result = meta.merge(create: create_result)

    selenium_result&.update!(result: :done, end_time: DateTime.now, last_step_no: 2)
    result
  rescue => e
    Rails.logger.error("[SubscStoreApiJob] #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace&.join("\n"))
    selenium_result&.update!(result: :error, end_time: DateTime.now, last_step_no: 2)
    raise
  end

  private

  def normalize_credit_card(credit_card)
    return credit_card if credit_card.is_a?(Hash)
    return JSON.parse(credit_card) if credit_card.is_a?(String) && credit_card.present?

    {}
  rescue JSON::ParserError
    {}
  end
end
