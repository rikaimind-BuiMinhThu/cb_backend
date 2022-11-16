json.code 1
json.data do
  json.merge! @push_message.as_json
  json.push_message_variables @push_message.push_message_variables
end
