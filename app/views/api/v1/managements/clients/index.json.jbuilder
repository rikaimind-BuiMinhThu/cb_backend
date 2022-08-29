json.code 1
json.data do
  json.clients @clients.each do |client|
    json.merge! client.as_json
    json.last_sign_in_at client.users.admin_client.maximum(:last_sign_in_at)&.strftime("%Y/%m/%d %H:%M:%S")

    instagram_user_ids = InstagramUser.where(instagram_account_id: client.users.admin_client.first&.instagram_account&.id).pluck(:id)
    json.instagram_user_count instagram_user_ids.length
    json.instagram_message_count ChatbotUsage.where(instagram_user_id: instagram_user_ids).count
    json.instagram_conversion_count Conversion.where(instagram_user_id: instagram_user_ids).count
  end
  json.total @total
end
