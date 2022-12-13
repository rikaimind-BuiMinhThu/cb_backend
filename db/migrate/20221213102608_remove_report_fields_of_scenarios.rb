class RemoveReportFieldsOfScenarios < ActiveRecord::Migration[7.0]
  def change
    remove_column :scenarios, :pc_count
    remove_column :scenarios, :tablet_count
    remove_column :scenarios, :smartphone_count
    remove_column :scenarios, :pc_conversion_count
    remove_column :scenarios, :tablet_conversion_count
    remove_column :scenarios, :smartphone_conversion_count
    remove_column :scenarios, :pc_open_chatbot_window_count
    remove_column :scenarios, :tablet_open_chatbot_window_count
    remove_column :scenarios, :smartphone_open_chatbot_window_count
  end
end
