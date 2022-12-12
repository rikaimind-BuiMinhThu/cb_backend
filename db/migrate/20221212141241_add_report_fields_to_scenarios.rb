class AddReportFieldsToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :pc_count, :integer, default: 0
    add_column :scenarios, :tablet_count, :integer, default: 0
    add_column :scenarios, :smartphone_count, :integer, default: 0
    add_column :scenarios, :pc_conversion_count, :integer, default: 0
    add_column :scenarios, :tablet_conversion_count, :integer, default: 0
    add_column :scenarios, :smartphone_conversion_count, :integer, default: 0
    add_column :scenarios, :pc_open_chatbot_window_count, :integer, default: 0
    add_column :scenarios, :tablet_open_chatbot_window_count, :integer, default: 0
    add_column :scenarios, :smartphone_open_chatbot_window_count, :integer, default: 0
  end
end
