class ChatbotUsageGroup < ApplicationRecord
  belongs_to :chatbot_usage
  belongs_to :message_group, optional: true
  belongs_to :message_bag, optional: true
end
