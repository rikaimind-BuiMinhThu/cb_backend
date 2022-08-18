json.code 1
json.data do
  json.message_group @message_group
  json.message_bags @message_group.message_bags.each do |message_bag|
    json.merge! message_bag.as_json
    json.messages message_bag.messages.each do |message|
      json.merge! message.as_json
      json.message_buttons message.message_buttons
      json.free_input message.free_input
    end
  end
end
