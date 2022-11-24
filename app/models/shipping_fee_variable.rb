class ShippingFeeVariable < ApplicationRecord
  belongs_to :prefecture
  belongs_to :chatbot

  validates :amount, presence: true
end
