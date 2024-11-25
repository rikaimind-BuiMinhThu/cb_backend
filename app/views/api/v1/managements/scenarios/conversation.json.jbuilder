json.code 1
json.message "Success"
json.data do
  json.scenario_name @scenario.name
  json.isUseOnlyRegularOrder @scenario.is_use_only_regular_order
  json.isUseFukushashiki @scenario.is_used_fukushashiki
  json.tamagoLandingPageUrl @scenario.tamago_repeat_config&.tamago_landing_page_url
  json.conversation JSON.parse(@scenario.conversation) unless @scenario.conversation.blank?
end
