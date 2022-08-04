class CustomItem < ApplicationRecord
  belongs_to :instagram_user

  validates :title, presence: true
  validates :value, presence: true
  validates :instagram_user_id, presence: true
end
