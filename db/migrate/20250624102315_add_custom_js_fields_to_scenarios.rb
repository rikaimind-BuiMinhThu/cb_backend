class AddCustomJsFieldsToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :is_used_custom_js_code, :boolean, default: false
    add_column :scenarios, :head_custom_js_code, :text
    add_column :scenarios, :top_body_custom_js_code, :text
    add_column :scenarios, :bottom_body_custom_js_code, :text
  end
end
