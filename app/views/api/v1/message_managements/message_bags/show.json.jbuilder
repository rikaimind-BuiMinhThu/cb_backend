json.code 1
json.data do
  json.message_bag @message_bag
  json.messages do
    @messages.each do |message|
      json.merge! message.as_json
      json.message_buttons do
        message.message_buttons do |message_button|
          json.merge! message_button.as_json
          json.message_button_labels message_button.message_button_labels
        end
      end
    end
  end
end
