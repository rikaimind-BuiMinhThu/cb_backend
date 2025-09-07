class UseMessagesLoadedPast < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :is_used_message_loaded_past, :boolean, default: false
  end
end
