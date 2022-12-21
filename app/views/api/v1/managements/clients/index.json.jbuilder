json.code 1
json.data do
  json.clients @clients.each do |client|
    json.merge! client.as_json
    json.last_sign_in_at client.users.admin_client.maximum(:last_sign_in_at)&.strftime("%Y/%m/%d %H:%M:%S")

    chatbot_usages = ChatbotUsage.where(instagram_account_id: client.users.admin_client.first&.instagram_account&.id).search_by_begin_date_and_end_date(@conversion_begin_date, @conversion_end_date)
    json.instagram_message_count chatbot_usages.count
    instagram_user_ids = chatbot_usages.group(:instagram_user_id).pluck(:instagram_user_id)
    json.instagram_user_count instagram_user_ids.length
    json.instagram_conversion_count Conversion.where(instagram_user_id: instagram_user_ids).search_by_begin_date_and_end_date(@conversion_begin_date, @conversion_end_date).count
    web_conversation_count = 0
    client.users.admin_client.each do |ac|
      ac.chatbots.each do |cb|
        cb.scenarios.each do |s|
          web_conversation_count += s.analytic_scenarios.count_conversion_by_begin_date_and_end_date(@conversion_begin_date, @conversion_end_date).length
        end
      end
    end
    json.web_conversation_count web_conversation_count
  end
  json.total @total
end
