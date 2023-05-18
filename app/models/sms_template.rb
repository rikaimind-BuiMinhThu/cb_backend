class SmsTemplate < ApplicationRecord
  belongs_to :user
  belongs_to :chatbot
end
