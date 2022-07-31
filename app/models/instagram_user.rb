class InstagramUser < ApplicationRecord
  has_many :instagram_user_labels
  has_many :message_button_labels, through: :instagram_user_labels
  belongs_to :instagram_account
  has_many :chatbot_usages
end
