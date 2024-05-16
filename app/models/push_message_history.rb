class PushMessageHistory < ApplicationRecord
  belongs_to :chatbot
  belongs_to :push_message, optional: true
  belongs_to :scenario, optional: true

  enum status: { failed: 0, success: 1 }
  enum sending_method: { email: 0, sms: 1 }
end
