class InstagramAccount < ApplicationRecord
  belongs_to :user, dependent: :destroy
end
