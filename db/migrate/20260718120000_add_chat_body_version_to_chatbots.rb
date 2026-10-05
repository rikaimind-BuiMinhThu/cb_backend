class AddChatBodyVersionToChatbots < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :chat_body_version, :string, null: false, default: "2.0"
  end
end
