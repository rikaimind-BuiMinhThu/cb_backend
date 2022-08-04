json.code 1
json.data do
  json.instagram_users @instagram_users.each do |instagram_user|
    json.merge! instagram_user.as_json
    # json.labels instagram_user.instagram_user_labels.select(:id, :name)
    # json.custom_items instagram_user.custom_items.select(:id, :title, :value)
    json.updated_at instagram_user.chatbot_usages.last.updated_at if instagram_user.chatbot_usages.last.present?
  end
end
