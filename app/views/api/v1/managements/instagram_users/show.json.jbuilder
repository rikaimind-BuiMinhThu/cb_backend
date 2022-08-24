json.code 1
json.data do
  json.instagram_users @instagram_user
  json.labels @instagram_user.instagram_user_labels.select(:id, :name, :is_admin_add).limit(10).order(created_at: :desc)
  json.need_support @instagram_user.supporting_users.exists?
  json.custom_items @instagram_user.custom_items.select(:id, :title, :value)
  json.message_histories @instagram_user.chatbot_usages.where(usage_type: [:dm_sent, :dm_received]).select(:id, :usage_type, :content, :created_at).order(created_at: :desc)
end
