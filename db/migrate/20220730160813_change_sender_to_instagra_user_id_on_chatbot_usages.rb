class ChangeSenderToInstagraUserIdOnChatbotUsages < ActiveRecord::Migration[7.0]
  def change
    add_reference :chatbot_usages, :instagram_user, index: true
    remove_column :chatbot_usages, :sender_id
  end
end
