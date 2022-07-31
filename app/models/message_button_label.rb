class MessageButtonLabel < ApplicationRecord
  has_many :instagram_user_labels
  has_many :instagram_users, through: :instagram_user_labels
  belongs_to :message_button
end
