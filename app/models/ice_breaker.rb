class IceBreaker < ApplicationRecord
  belongs_to :instagram_account
  belongs_to :message_bag, optional: true

  private

  def self.validate_size!(instagram_account_id)
    return false if IceBreaker.where(instagram_account_id: instagram_account_id).size >= 4
    return true
  end
end
