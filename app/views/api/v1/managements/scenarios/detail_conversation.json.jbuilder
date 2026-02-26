json.code 1
json.message "Success"
json.data do
  json.scenario_name @scenario.name
  json.scenario_type @scenario.scenario_type || 'payment'
  json.isUseOnlyRegularOrder @scenario.is_use_only_regular_order
  json.isUseFukushashiki @scenario.is_used_fukushashiki
  json.custom_css_content @scenario.custom_css_content
  json.is_used_custom_css @scenario.is_used_custom_css
  json.is_used_err_msg_by_js @scenario.is_used_err_msg_by_js
  json.err_msg_js_code @scenario.err_msg_js_code
  json.is_used_custom_js_code @scenario.is_used_custom_js_code
  json.head_custom_js_code @scenario.head_custom_js_code
  json.top_body_custom_js_code @scenario.top_body_custom_js_code
  json.bottom_body_custom_js_code @scenario.bottom_body_custom_js_code
  json.timer_config JSON.parse(@scenario.timer_config) unless @scenario.timer_config.blank?
  json.tamagoLandingPageUrl @landing_page_product_url
  json.conversation JSON.parse(@scenario.conversation) unless @scenario.conversation.blank?
  json.is_used_message_loaded_past @scenario.is_used_message_loaded_past
  json.use_fullwidth_chatbot_mobile @scenario.use_fullwidth_chatbot_mobile
end
