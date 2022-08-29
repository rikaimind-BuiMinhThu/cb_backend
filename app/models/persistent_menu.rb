class PersistentMenu < ApplicationRecord
  URL_REG = /\A(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})\z/

  belongs_to :instagram_account
  belongs_to :message_bag, optional: true

  validates :url, allow_blank: true, format: URL_REG

  def check_url
    return if url.blank? || HttpManager.new(url).uri?
    errors.add(:url, "invalid")
  end

  private

  def self.validate_size!(instagram_account_id)
    return false if PersistentMenu.where(instagram_account_id: instagram_account_id).size >= 5
    return true
  end
end
