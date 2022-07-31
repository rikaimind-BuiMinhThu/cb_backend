json.code 1
json.data do
  json.instagram_users @instagram_user
  json.labels @instagram_user.message_button_labels.pluck(:label_name)
  json.message_histories @instagram_user.chatbot_usages.where(usage_type: [:dm_sent, :dm_received]).select(:id, :usage_type, :content, :created_at)
end
