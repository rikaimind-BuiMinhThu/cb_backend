class ScenarioUserResponseSeleniumResult < ApplicationRecord
  belongs_to :scenario

  enum result: { open: 0, running: 1, done: 2, error: 3 }

  scope :for_chatbot, ->(id) { where(chatbot_id: id) }
  scope :for_client, ->(id) { where(client_id: id) }
  scope :for_listing, ->(chatbot_id:, client_id:) {
    relation = all
    relation = relation.for_chatbot(chatbot_id) if chatbot_id.present?
    relation = relation.for_client(client_id) if client_id.present?
    relation
  }
  scope :for_visitor, ->(scenario_id, user_input_id) { where(scenario_id: scenario_id, user_input_id: user_input_id) }
  scope :stale_queued, ->(before) {
    where(result: :running, last_step_description: "queued").where("updated_at < ?", before)
  }

  def rpa_steps_array
    return [] if rpa_steps.blank?

    JSON.parse(rpa_steps)
  rescue JSON::ParserError
    []
  end

  def rpa_steps_array=(steps)
    self.rpa_steps = JSON.generate(Array(steps))
  end

  def append_rpa_step(step)
    steps = rpa_steps_array
    steps << step
    self.rpa_steps_array = steps
    save!
  end

  def path_label
    radio_label_for(%w[path order_path], path)
  end

  def payment_label
    radio_label_for(%w[payment_method], payment)
  end

  def token_failure?
    error_kind.to_s == "token_failure"
  end

  def submitted_to_cart?
    rpa_steps_array.any? { |step| step["name"].to_s == "submit_order" }
  end

  def retryable?
    return false if order_submitted_at.present?

    error? && (token_failure? || !submitted_to_cart?)
  end

  def chrome_slot_defer_count
    rpa_steps_array.count { |step| step["name"].to_s == "chrome_slot_defer" }
  end

  def chrome_slot_retry_count
    rpa_steps_array.count { |step| step["name"].to_s == "chrome_slot_retry" }
  end

  private

  def radio_label_for(save_names, key)
    return key if key.blank?

    conversation_radio_text(save_names, key).presence || key
  end

  def conversation_radio_text(save_names, key)
    data = parsed_conversation
    messages = data.is_a?(Hash) ? Array(data["messages"]) : Array(data)
    messages.each do |message|
      Array(message["message_content"]).each do |content|
        radio = content["radio_button"]
        next if radio.blank?
        next unless save_names.include?(radio["save_input_content"].to_s)

        match = Array(radio["default"]).find { |option| option["value"].to_s == key.to_s }
        text = match && match["text"]
        return text if text.present?
      end
    end
    nil
  end

  def parsed_conversation
    raw = scenario&.conversation
    return {} if raw.blank?
    return raw if raw.is_a?(Hash) || raw.is_a?(Array)

    JSON.parse(raw)
  rescue JSON::ParserError
    {}
  end
end
