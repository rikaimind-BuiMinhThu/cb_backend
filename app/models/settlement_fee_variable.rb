class SettlementFeeVariable < ApplicationRecord
  belongs_to :chatbot

  validates :variable_value, presence: true
  validates :commission, presence: true
end
