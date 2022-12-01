class AddReportFieldsToChatbots < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :num_of_pc_count, :integer, default: 0
    add_column :chatbots, :num_of_tablet_count, :integer, default: 0
    add_column :chatbots, :num_of_sp_count, :integer, default: 0
    add_column :chatbots, :num_of_conversion_count, :integer, default: 0
    add_column :chatbots, :num_of_open_chatbot_window_count, :integer, default: 0
  end
end
