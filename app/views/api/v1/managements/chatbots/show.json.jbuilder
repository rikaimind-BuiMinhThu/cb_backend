json.code 1
json.data do
  json.merge! @chatbot.as_json
  json.user_chatbots @chatbot.user_chatbots.each do |user_chatbot|
    json.merge! user_chatbot.as_json
    json.full_name user_chatbot.user.full_name
  end
end
