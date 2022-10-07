json.code 1
json.message "Success"
json.data do
  json.scenario_name @scenario.name
  json.conversation JSON.parse(@scenario.conversation) unless @scenario.conversation.blank?
end
