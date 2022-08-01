json.code 1
json.data do
  json.message_bag @message_bag
  json.messages @messages.each do |message|
    json.merge! message.as_json
    json.message_buttons message.message_buttons do |message_button|
      json.merge! message_button.as_json
      json.message_button_labels message_button.message_button_labels
    end
    if message.free_input.present?
      json.free_input do
        json.merge! message.free_input.as_json
        json.free_input_labels message.free_input&.free_input_labels
      end
    end
  end
end
