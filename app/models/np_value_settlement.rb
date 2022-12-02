class NpValueSettlement < ApplicationRecord
  belongs_to :chatbot

  validates :np_settlement_min_value, presence: true
  validates :np_settlement_max_value, presence: true, numericality: { greater_than_or_equal_to: :np_settlement_min_value }
  validates :np_settlement_fee_value, presence: true
end
