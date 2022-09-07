json.code 1
json.data do
  json.clients @clients.each do |client|
    json.merge! client.as_json
    json.last_sign_in_at client.users.admin_client.maximum(:last_sign_in_at)&.strftime("%Y/%m/%d %H:%M:%S")

    chatbot_usages = ChatbotUsage.where(instagram_account_id: instagram_account_id).search_by_begin_date_and_end_date(@conversion_begin_date, @conversion_end_date)
    json.instagram_message_count chatbot_usages.count
    instagram_user_ids = chatbot_usages.group(:instagram_user_id).pluck(:instagram_user_id)
    json.instagram_user_count chatbot_usages.group(:instagram_user_id).length
    json.instagram_conversion_count Conversion.where(instagram_user_id: instagram_user_ids).search_by_begin_date_and_end_date(@conversion_begin_date, @conversion_end_date).count
  end
  json.total @total
end
