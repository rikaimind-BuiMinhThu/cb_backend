class InstagramUser < ApplicationRecord
  has_many :instagram_user_message_button_labels
  has_many :message_button_labels, through: :instagram_user_message_button_labels
  belongs_to :instagram_account
end
