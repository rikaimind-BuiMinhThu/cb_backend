require "ostruct"

class Client < ApplicationRecord
  acts_as_paranoid
  has_many :users, dependent: :destroy
  has_one :client_email, dependent: :destroy

  encrypts :reply_smtp_gmail_app_password, deterministic: true

  enum status: {active: 0, pause: 1, ended: 2, trial: 3}

  mount_base64_uploader :logo_url, PictureUploader

  # validates :subscription_end_at, comparison: { greater_than: :subscription_start_at }

  validate :subscription_start_at_cannot_be_greater_than_subscription_end_at

  enum cart_system: {
    cart_system_none: 0,
    tamago_repeat: 1,
    subsc_store: 2,
    shopify: 3,
    ec_force: 4,
    repeat_plus: 5
  }

  enum order_execution_mode: {
    undecided: 0,
    fukushashiki_only: 1,
    api_only: 2,
    rpa: 3
  }, _prefix: :order_execution

  validate :subsc_store_api_credentials_present, if: :requires_subsc_store_api_credentials?

  def subsc_store_api_credentials?
    shop_url.present? && client_id.present? && client_secret.present?
  end

  def subsc_store_api_ready?
    use_subsc_store_mock? || subsc_store_api_credentials?
  end

  def requires_subsc_store_api_credentials?
    subsc_store? && order_execution_api_only? && !use_subsc_store_mock?
  end

  def use_subsc_store_mock?
    return false unless has_attribute?(:is_use_mock_response)

    subsc_store? && order_execution_api_only? && ActiveModel::Type::Boolean.new.cast(is_use_mock_response)
  end

  def extra_config=(value)
    super(encode_json_column(value))
  end

  def mock_response=(value)
    super(encode_json_column(value))
  end

  def extra_config_hash
    parse_json_column(has_attribute?(:extra_config) ? extra_config : nil)
  end

  def mock_response_hash
    parse_json_column(has_attribute?(:mock_response) ? mock_response : nil)
  end

  def subsc_store_config
    hash = extra_config_hash
    (hash["subsc_store"] || hash[:subsc_store] || hash).with_indifferent_access
  end

  def upsell_available?
    ActiveModel::Type::Boolean.new.cast(subsc_store_config.dig("upsell", "enabled"))
  end

  def subsc_store_api_credentials_present
    return if subsc_store_api_credentials?

    errors.add(:base, "サブスクストア API の Shop URL / Client ID / Client Secret を設定してください")
  end

  def reply_smtp_credentials
    return nil if reply_smtp_gmail.blank?

    OpenStruct.new(
      email: reply_smtp_gmail,
      password: reply_smtp_gmail_app_password
    )
  end

  def self.get_cart_system_by_user_id(user_id)
    user = User.find_by(id: user_id)


    if user.present? && user.client_id.present?
      client = Client.find_by(id: user.client_id)
      return client.cart_system if client.present?
    end

    return cart_system.cart_system_none
  end

  def subscription_start_at_cannot_be_greater_than_subscription_end_at
    if subscription_start_at.present? && subscription_end_at.present? && subscription_start_at > subscription_end_at
      errors.add(:subscription_start_at, "can't be greater than subscription end at")
    end
  end

  def self.ransackable_associations(auth_object = nil)
    ["client_email", "users"]
  end
    
  def self.ransackable_attributes(auth_object = nil)
    ["address", "building_name", "cart_system", "created_at", "deleted_at", "department_name", "email", "enterprise_type", "enterprise_type_2", "id", "is_instagram", "is_line", "is_tiktok", "is_web", "logo_url", "municipality", "name", "name_katakana", "note", "phone_number", "plan", "prefecture", "price", "responsible_person", "responsible_person_katakana", "status", "subscription_end_at", "subscription_start_at", "title", "unit_price_instagram", "unit_price_line", "unit_price_tiktok", "unit_price_web", "updated_at", "url", "zip_code", "shop_url", "client_id", "client_secret", "reply_smtp_gmail"]
  end

  private

  def parse_json_column(value)
    return {} if value.blank?

    parsed = value.is_a?(String) ? JSON.parse(value) : value
    parsed.is_a?(Hash) ? parsed : {}
  rescue JSON::ParserError
    {}
  end

  def encode_json_column(value)
    return nil if value.blank?

    hash = value.respond_to?(:to_unsafe_h) ? value.to_unsafe_h : value
    return hash if hash.is_a?(String)
    return nil unless hash.respond_to?(:as_json)

    JSON.generate(hash.as_json)
  end
end
