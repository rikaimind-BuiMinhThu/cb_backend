json.code 1
json.data do
  json.user_chatbots @user_chatbots.each do |user_chatbot|
    json.extract! user_chatbot, :id, :role, :chatbot_id
    json.full_name user_chatbot.user.full_name
    json.email user_chatbot.user.email
  end
end
