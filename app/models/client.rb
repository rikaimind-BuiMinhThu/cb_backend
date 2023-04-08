class Client < ApplicationRecord
  acts_as_paranoid
  has_many :users, dependent: :destroy
  has_one :client_email, dependent: :destroy

  enum status: {active: 0, pause: 1, ended: 2, trial: 3}
  enum plan: {startup: 0, premium: 1, expert: 2, complete: 4}

  mount_base64_uploader :logo_url, PictureUploader

  # validates :subscription_end_at, comparison: { greater_than: :subscription_start_at }

  validate :subscription_start_at_cannot_be_greater_than_subscription_end_at

  enum cart_system: {
    cart_system_none: 0,
    tamago_repeat: 1,
    shopify: 2
  }

  def subscription_start_at_cannot_be_greater_than_subscription_end_at
    if subscription_start_at.present? && subscription_end_at.present? && subscription_start_at > subscription_end_at
      errors.add(:subscription_start_at, "can't be greater than subscription end at")
    end
  end

  def self.ransackable_associations(auth_object = nil)
    ["client_email", "users"]
  end
    
  def self.ransackable_attributes(auth_object = nil)
    ["address", "building_name", "cart_system", "created_at", "deleted_at", "department_name", "email", "enterprise_type", "enterprise_type_2", "id", "is_instagram", "is_line", "is_tiktok", "is_web", "logo_url", "municipality", "name", "name_katakana", "note", "phone_number", "plan", "prefecture", "price", "responsible_person", "responsible_person_katakana", "status", "subscription_end_at", "subscription_start_at", "title", "unit_price_instagram", "unit_price_line", "unit_price_tiktok", "unit_price_web", "updated_at", "url", "zip_code"]
    end
    
end
