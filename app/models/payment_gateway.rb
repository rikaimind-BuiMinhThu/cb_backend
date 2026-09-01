class PaymentGateway < ApplicationRecord
  belongs_to :user
  enum payment_agency: {gmo: 0, np_payment: 1, zeus: 2}
  enum mode: {test: 0, product: 1}
  enum is_default: {yes: true, no: false}, _prefix: :is_default

  validates :gateway_name, presence: true
  validates :payment_agency, presence: true
  validates :mode, presence: true
  validates :shop_id, presence: true, if: -> { gmo? }
  validates :merchant_code, presence: true, if: -> { np_payment? }
  validates :sp_code, presence: true, if: -> { np_payment? }
  validates :terminal_id, presence: true, if: -> { np_payment? }
  validates :token_js_url, presence: true, if: -> { zeus? }
  validates :client_ip, presence: true, if: -> { zeus? }
  validates :ipcode, presence: true, if: -> { zeus? }
  validate :zeus_cannot_be_default_charge

  scope :charge_gateways, -> { where.not(payment_agency: payment_agencies[:zeus]) }

  private

  def zeus_cannot_be_default_charge
    return unless zeus? && is_default_yes?

    errors.add(:is_default, "ZEUS cannot be the default charge gateway")
  end
end
