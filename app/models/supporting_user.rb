class SupportingUser < ApplicationRecord
  belongs_to :instagram_account
  belongs_to :instagram_user
end
