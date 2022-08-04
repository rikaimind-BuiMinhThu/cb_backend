class InstagramUserLabel < ApplicationRecord
  belongs_to :instagram_user

  validates :name, presence: true
  validates :instagram_user_id, presence: true
end
