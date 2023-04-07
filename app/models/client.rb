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
    subsc_store: 2
  }

  def subscription_start_at_cannot_be_greater_than_subscription_end_at
    if subscription_start_at.present? && subscription_end_at.present? && subscription_start_at > subscription_end_at
      errors.add(:subscription_start_at, "can't be greater than subscription end at")
    end
  end

end
