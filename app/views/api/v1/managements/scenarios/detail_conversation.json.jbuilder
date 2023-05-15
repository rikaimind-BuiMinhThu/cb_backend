json.code 1
json.message "Success"
json.data do
  json.scenario_name @scenario.name
  json.isUseOnlyRegularOrder @scenario.is_use_only_regular_order
  json.tamagoLandingPageUrl @landing_page_product_url
  json.conversation JSON.parse(@scenario.conversation) unless @scenario.conversation.blank?
end
