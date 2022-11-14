class PaymentGateway < ApplicationRecord
  belongs_to :user
  enum payment_agency: {gmo: 0, np_payment: 1}
  enum mode: {test: 0, product: 1}

  validates :gateway_name, presence: true
  validates :payment_agency, presence: true
  validates :mode, presence: true
  validates :shop_id, presence: true, if: -> { gmo? }
  validates :shop_pass, presence: true, if: -> { gmo? }
  validates :merchant_code, presence: true, if: -> { np_payment? }
  validates :sp_code, presence: true, if: -> { np_payment? }
  validates :terminal_id, presence: true, if: -> { np_payment? }
end
