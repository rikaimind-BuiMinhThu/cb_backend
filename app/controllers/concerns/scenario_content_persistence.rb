module ScenarioContentPersistence
  extend ActiveSupport::Concern

  private

  def apply_scenario_content_params!(record, chatbot: nil)
    if params[:conversation].present?
      record.conversation = JSON.generate(params[:conversation].as_json)
    end

    record.scenario_type = params[:scenario_type] if params[:scenario_type].present?
    record.landing_page_product_url = params[:landing_page_product_url]

    apply_merchandise_fields!(record, chatbot)
    apply_customization_fields!(record)
    apply_extra_config!(record)
    record.save!
  end

  def apply_merchandise_fields!(record, chatbot)
    shopify_context = chatbot.nil? || record_is_shopify_payment?(record, chatbot)

    if shopify_context
      if params.key?(:merchandise_id) || params.key?("merchandise_id")
        merch_param = params[:merchandise_id].to_s.strip
        record.merchandise_id =
          if merch_param.blank?
            nil
          elsif merch_param.start_with?("gid://shopify/ProductVariant/")
            merch_param
          else
            "gid://shopify/ProductVariant/#{merch_param}"
          end
      end

      record.is_used_crosssell = params[:is_used_crosssell]
      if record.is_used_crosssell && (params.key?(:product_id_cross_sell) || params.key?("product_id_cross_sell"))
        cross_param = params[:product_id_cross_sell].to_s.strip
        record.product_id_cross_sell =
          if cross_param.blank?
            nil
          elsif cross_param.start_with?("gid://shopify/ProductVariant/")
            cross_param
          else
            "gid://shopify/ProductVariant/#{cross_param}"
          end
      else
        record.product_id_cross_sell = nil
      end
    else
      record.merchandise_id = nil
      record.is_used_crosssell = false
      record.product_id_cross_sell = nil
    end
  end

  def record_is_shopify_payment?(record, chatbot)
    return true if record.is_a?(ScenarioTemplate)

    record.shopify_payment_merchandise_context?
  end

  def apply_customization_fields!(record)
    record.is_use_only_regular_order = params[:is_use_only_regular_order]
    apply_execution_policy!(record)
    record.is_used_custom_css = params[:is_used_custom_css]
    record.custom_css_content = params[:custom_css_content]
    record.is_used_err_msg_by_js = params[:is_used_err_msg_by_js]
    record.err_msg_js_code = params[:err_msg_js_code]
    record.err_msg_setting_mode = params[:err_msg_setting_mode] if params[:err_msg_setting_mode].present?
    record.err_msg_field_selectors = params[:err_msg_field_selectors]
    record.err_msg_form_selectors = params[:err_msg_form_selectors]
    record.launch_button_selectors = params[:launch_button_selectors]
    record.is_used_custom_js_code = params[:is_used_custom_js_code]
    record.head_custom_js_code = params[:head_custom_js_code]
    record.top_body_custom_js_code = params[:top_body_custom_js_code]
    record.bottom_body_custom_js_code = params[:bottom_body_custom_js_code]
    record.timer_config = JSON.generate(params[:timer_config].as_json) if params[:timer_config].present?
    record.is_used_message_loaded_past = params[:is_used_message_loaded_past]
    record.use_fullwidth_chatbot_mobile = params[:use_fullwidth_chatbot_mobile]
    record.is_clear_landing_page_session = params[:is_clear_landing_page_session]
  end

  def apply_extra_config!(record)
    return unless record.respond_to?(:extra_config=)

    incoming = {
      auto_logout: params[:auto_logout],
      is_use_amazon_pay: params[:is_use_amazon_pay],
      allowed_lp_domains: params[:allowed_lp_domains],
      lp_integration_mode: params[:lp_integration_mode],
      amazon_pay_config: params[:amazon_pay_config],
      tag_firing: params[:tag_firing],
    }.compact

    extra = record.extra_config_hash.merge(incoming)
    record.extra_config = extra.present? ? JSON.generate(extra.as_json) : nil
  end

  def apply_execution_policy!(record)
    if params.key?(:execution_policy) && params[:execution_policy].present?
      record.execution_policy = params[:execution_policy]
    else
      record.execution_policy = ActiveModel::Type::Boolean.new.cast(params[:is_used_fukushashiki]) ? :fukushashiki : :rpa
    end
    record.sync_fukushashiki_from_execution_policy!
  end
end
