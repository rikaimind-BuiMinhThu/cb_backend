class RemoveReportFieldsOfChatbots < ActiveRecord::Migration[7.0]
  def change
    remove_column :chatbots, :num_of_pc_count
    remove_column :chatbots, :num_of_tablet_count
    remove_column :chatbots, :num_of_sp_count
    remove_column :chatbots, :num_of_conversion_count
    remove_column :chatbots, :num_of_open_chatbot_window_count
  end
end
