class PersistentMenu < ApplicationRecord
  belongs_to :instagram_account
  belongs_to :message_bag, optional: true

  validate :check_url

  def check_url
    return if HttpManager.new(url).uri?
    errors.add(:url, "invalid")
  end

  private

  def self.validate_size!(instagram_account_id)
    return false if PersistentMenu.where(instagram_account_id: instagram_account_id).size >= 5
    return true
  end
end
