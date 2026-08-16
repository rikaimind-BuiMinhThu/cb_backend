class Scenario < ApplicationRecord
  belongs_to :chatbot
  has_many :analytic_scenarios, dependent: :destroy
  has_many :scenario_pages, dependent: :destroy
  has_many :scenario_user_responses
  has_many :scenario_user_response_messages, dependent: :destroy
  has_one :tamago_repeat_config

  validates :name, presence: true, uniqueness: { scope: :chatbot }
  validates :scenario_type, inclusion: { in: %w[payment faq] }, allow_nil: false

  enum order_execution_mode: {
    fukushashiki_only: 1,
    api_only: 2,
    rpa: 3
  }, _prefix: :order_execution

  def extra_config_hash
    return {} unless has_attribute?(:extra_config)
    return {} if extra_config.blank?

    parsed = extra_config.is_a?(String) ? JSON.parse(extra_config) : extra_config
    parsed.is_a?(Hash) ? parsed : {}
  rescue JSON::ParserError
    {}
  end

  def extra_config_hash=(value)
    hash = value.respond_to?(:to_unsafe_h) ? value.to_unsafe_h : value
    self.extra_config = hash.present? ? JSON.generate(hash.as_json) : nil
  end

  def owning_client
    chatbot&.user&.client
  end

  def subsc_store_config
    client = owning_client
    if client&.has_attribute?(:extra_config) && client.extra_config.present?
      return client.subsc_store_config
    end

    hash = extra_config_hash
    (hash["subsc_store"] || hash[:subsc_store] || hash).with_indifferent_access
  end

  def resolved_order_execution_mode
    OrderExecutionMode.resolve(owning_client, self)
  end

  def upsell_available?
    client = owning_client
    return client.upsell_available? if client&.has_attribute?(:extra_config) && client.extra_config.present?

    ActiveModel::Type::Boolean.new.cast(subsc_store_config.dig("upsell", "enabled"))
  end

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
