json.code 1
json.message "Success"
json.data do
  extra = @scenario_template.extra_config_hash

  json.cart_system nil
  json.scenario_name @scenario_template.name
  json.scenario_type @scenario_template.scenario_type || "payment"
  json.isUseOnlyRegularOrder @scenario_template.is_use_only_regular_order
  json.isUseFukushashiki @scenario_template.is_used_fukushashiki
  json.custom_css_content @scenario_template.custom_css_content
  json.is_used_custom_css @scenario_template.is_used_custom_css
  json.is_used_err_msg_by_js @scenario_template.is_used_err_msg_by_js
  json.err_msg_js_code @scenario_template.err_msg_js_code
  json.err_msg_setting_mode @scenario_template.err_msg_setting_mode
  json.err_msg_field_selectors @scenario_template.err_msg_field_selectors
  json.err_msg_form_selectors @scenario_template.err_msg_form_selectors
  json.launch_button_selectors @scenario_template.launch_button_selectors
  json.is_used_custom_js_code @scenario_template.is_used_custom_js_code
  json.head_custom_js_code @scenario_template.head_custom_js_code
  json.top_body_custom_js_code @scenario_template.top_body_custom_js_code
  json.bottom_body_custom_js_code @scenario_template.bottom_body_custom_js_code
  json.timer_config JSON.parse(@scenario_template.timer_config) unless @scenario_template.timer_config.blank?
  json.tamagoLandingPageUrl @landing_page_product_url
  json.merchandise_id @scenario_template.merchandise_id
  json.conversation JSON.parse(@scenario_template.conversation) unless @scenario_template.conversation.blank?
  json.is_used_message_loaded_past @scenario_template.is_used_message_loaded_past
  json.use_fullwidth_chatbot_mobile @scenario_template.use_fullwidth_chatbot_mobile
  json.is_clear_landing_page_session @scenario_template.is_clear_landing_page_session
  json.is_used_crosssell @scenario_template.is_used_crosssell
  json.product_id_cross_sell @scenario_template.product_id_cross_sell
  json.auto_logout extra["auto_logout"]
  json.is_use_amazon_pay extra["is_use_amazon_pay"]
  json.allowed_lp_domains extra["allowed_lp_domains"]
  json.lp_integration_mode extra["lp_integration_mode"]
  json.amazon_pay_config extra["amazon_pay_config"]
end
