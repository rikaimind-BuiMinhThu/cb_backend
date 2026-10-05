class CreateScenarioTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :scenario_templates do |t|
      t.string :name, null: false
      t.string :scenario_type, default: "payment", null: false
      t.mediumtext :conversation
      t.string :landing_page_product_url
      t.string :merchandise_id
      t.boolean :is_used_crosssell, default: false, null: false
      t.string :product_id_cross_sell
      t.boolean :is_use_only_regular_order, default: false
      t.boolean :is_used_fukushashiki, default: false
      t.boolean :is_used_custom_css, default: false
      t.text :custom_css_content
      t.boolean :is_used_custom_js_code, default: false
      t.text :head_custom_js_code
      t.text :top_body_custom_js_code
      t.text :bottom_body_custom_js_code
      t.boolean :is_used_err_msg_by_js, default: false
      t.text :err_msg_js_code
      t.string :err_msg_setting_mode, default: "js"
      t.text :err_msg_field_selectors
      t.text :err_msg_form_selectors
      t.text :launch_button_selectors
      t.text :timer_config
      t.boolean :is_used_message_loaded_past, default: false
      t.boolean :use_fullwidth_chatbot_mobile, default: false
      t.boolean :is_clear_landing_page_session, default: false, null: false
      t.text :extra_config
      t.bigint :created_by_id

      t.timestamps
    end

    add_index :scenario_templates, :name, unique: true
    add_index :scenario_templates, :created_by_id
  end
end
