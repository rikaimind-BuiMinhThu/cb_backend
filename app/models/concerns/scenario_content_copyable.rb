module ScenarioContentCopyable
  extend ActiveSupport::Concern

  CONTENT_ATTRIBUTES = %w[
    scenario_type
    conversation
    landing_page_product_url
    merchandise_id
    is_used_crosssell
    product_id_cross_sell
    is_use_only_regular_order
    is_used_fukushashiki
    execution_policy
    is_used_custom_css
    custom_css_content
    is_used_custom_js_code
    head_custom_js_code
    top_body_custom_js_code
    bottom_body_custom_js_code
    is_used_err_msg_by_js
    err_msg_js_code
    err_msg_setting_mode
    err_msg_field_selectors
    err_msg_form_selectors
    launch_button_selectors
    timer_config
    is_used_message_loaded_past
    use_fullwidth_chatbot_mobile
    is_clear_landing_page_session
    extra_config
  ].freeze

  class_methods do
    def copy_content_attributes(from:, to:)
      CONTENT_ATTRIBUTES.each do |attr|
        to.public_send("#{attr}=", from.public_send(attr)) if from.respond_to?(attr) && to.respond_to?("#{attr}=")
      end
      to
    end
  end
end
