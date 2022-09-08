json.code 1
json.data do
  json.instagram_users @instagram_users.each do |instagram_user|
    json.merge! instagram_user.as_json
    json.need_support instagram_user.supporting_users.exists?
    json.client_name instagram_user.instagram_account.user&.client&.name if current_user.admin_deel?
    # json.labels instagram_user.instagram_user_labels.select(:id, :name)
    # json.custom_items instagram_user.custom_items.select(:id, :title, :value)
    json.num_of_messages_sent instagram_user.chatbot_usages.dm_received.count
    json.num_of_conversions instagram_user.conversions.count
    json.updated_at instagram_user.chatbot_usages.last.updated_at if instagram_user.chatbot_usages&.last.present?
  end
end
