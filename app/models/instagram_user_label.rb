class InstagramUserLabel < ApplicationRecord
  belongs_to :instagram_user

  validates :name, presence: true, uniqueness: { scope: :instagram_user_id, message: "label has unique" }
  validates :instagram_user_id, presence: true
end
