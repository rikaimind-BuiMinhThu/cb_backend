json.code 1
json.message "Success"
json.data do
  extra = @scenario.extra_config_hash

  json.cart_system @client&.cart_system
  json.scenario_name @scenario.name
  json.scenario_type @scenario.scenario_type || 'payment'
  json.isUseOnlyRegularOrder @scenario.is_use_only_regular_order
  json.isUseFukushashiki @scenario.is_used_fukushashiki
  json.custom_css_content @scenario.custom_css_content
  json.is_used_custom_css @scenario.is_used_custom_css
  json.is_used_err_msg_by_js @scenario.is_used_err_msg_by_js
  json.err_msg_js_code @scenario.err_msg_js_code
  json.err_msg_setting_mode @scenario.err_msg_setting_mode
  json.err_msg_field_selectors @scenario.err_msg_field_selectors
  json.err_msg_form_selectors @scenario.err_msg_form_selectors
  json.launch_button_selectors @scenario.launch_button_selectors
  json.is_used_custom_js_code @scenario.is_used_custom_js_code
  json.head_custom_js_code @scenario.head_custom_js_code
  json.top_body_custom_js_code @scenario.top_body_custom_js_code
  json.bottom_body_custom_js_code @scenario.bottom_body_custom_js_code
  json.is_used_html_ugc @scenario.is_used_html_ugc
  json.is_ugc_instagram @scenario.is_ugc_instagram
  json.is_ugc_tiktok @scenario.is_ugc_tiktok
  json.is_ugc_review @scenario.is_ugc_review
  json.html_ugc_config_content @scenario.html_ugc_config_content
  json.timer_config JSON.parse(@scenario.timer_config) unless @scenario.timer_config.blank?
  json.tamagoLandingPageUrl @landing_page_product_url
  json.merchandise_id @scenario.merchandise_id_for_api
  json.conversation JSON.parse(@scenario.conversation) unless @scenario.conversation.blank?
  json.is_used_message_loaded_past @scenario.is_used_message_loaded_past
  json.use_fullwidth_chatbot_mobile @scenario.use_fullwidth_chatbot_mobile
  json.is_clear_landing_page_session @scenario.is_clear_landing_page_session
  json.is_used_crosssell @scenario.is_used_crosssell
  json.product_id_cross_sell @scenario.product_id_cross_sell_for_api
  json.auto_logout extra["auto_logout"]
  json.is_use_amazon_pay extra["is_use_amazon_pay"]
  json.allowed_lp_domains extra["allowed_lp_domains"]
  json.lp_integration_mode extra["lp_integration_mode"]
  json.amazon_pay_config extra["amazon_pay_config"]
end
