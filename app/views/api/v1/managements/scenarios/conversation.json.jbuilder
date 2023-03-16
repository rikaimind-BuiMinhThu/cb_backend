json.code 1
json.message "Success"
json.data do
  json.scenario_name @scenario.name
  json.tamagoLandingPageUrl @scenario.tamago_repeat_config&.tamago_landing_page_url
  json.conversation JSON.parse(@scenario.conversation) unless @scenario.conversation.blank?
end
