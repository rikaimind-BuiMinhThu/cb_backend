json.code 1
json.data @push_messages.each do |push_message|
  json.merge! push_message.as_json
  json.variables push_message.push_message_variables
end
json.total @total
