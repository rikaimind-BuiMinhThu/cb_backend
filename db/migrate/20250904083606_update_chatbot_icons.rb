class UpdateChatbotIcons < ActiveRecord::Migration[7.0]
  def change
    # Add new icon fields
    add_column :chatbots, :opening_bot_icon, :string
    add_column :chatbots, :closing_bot_icon, :string
    
    # Remove old message_icon field
    remove_column :chatbots, :message_icon, :string
  end
end