class Scenario < ApplicationRecord
  include ScenarioExtraConfig

  belongs_to :chatbot
  has_many :analytic_scenarios, dependent: :destroy
  has_many :scenario_pages, dependent: :destroy
  has_many :scenario_user_responses
  has_many :scenario_user_response_messages, dependent: :destroy
  has_one :tamago_repeat_config

  validates :name, presence: true, uniqueness: { scope: :chatbot }
  validates :scenario_type, inclusion: { in: %w[payment faq] }, allow_nil: false

  def shopify_payment_merchandise_context?
    uid = chatbot&.user_id
    return false unless uid
    return false unless (scenario_type.presence || "payment").to_s == "payment"
    Client.get_cart_system_by_user_id(uid).to_s == "shopify"
  end

  def merchandise_id_for_api
    return nil unless shopify_payment_merchandise_context?
    merchandise_id
  end

  def product_id_cross_sell_for_api
    return nil unless shopify_payment_merchandise_context?
    return nil unless is_used_crosssell
    product_id_cross_sell
  end
end
