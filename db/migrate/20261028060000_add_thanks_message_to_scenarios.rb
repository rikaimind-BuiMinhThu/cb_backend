class AddThanksMessageToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :is_used_thanks_message, :boolean, default: false, null: false
    add_column :scenarios, :thanks_message_html, :text
    add_column :scenario_templates, :is_used_thanks_message, :boolean, default: false, null: false
    add_column :scenario_templates, :thanks_message_html, :text
  end
end
