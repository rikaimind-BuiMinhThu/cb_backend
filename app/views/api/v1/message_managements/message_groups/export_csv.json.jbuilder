json.code 1
json.data do
  json.message_groups @message_groups
  json.message_bags @message_groups.message_bags.each do |message_bag|
    json.merge! message_bag.as_json
    json.messages message_bag.messages.each do |message|
      json.merge! message.as_json
      json.message_buttons message.message_buttons
      json.free_inputs message.free_inputs
    end
  end
end
