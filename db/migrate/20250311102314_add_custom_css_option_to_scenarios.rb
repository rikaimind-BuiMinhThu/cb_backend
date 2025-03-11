class AddCustomCssOptionToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :is_used_custom_css, :boolean, default: false
    add_column :scenarios, :custom_css_content, :text
  end
end
