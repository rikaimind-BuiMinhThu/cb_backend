class SpecifyPaymentVariable < ApplicationRecord
  belongs_to :payment_gateway
  belongs_to :chatbot

  validates :variable_value, presence: true
end
