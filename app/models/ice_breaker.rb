class IceBreaker < ApplicationRecord
  belongs_to :instagram_account

  private

  def self.validate_size!(instagram_account_id)
    return false if PersistentMenu.where(instagram_account_id: instagram_account_id).size >= 4
    return true
  end
end
