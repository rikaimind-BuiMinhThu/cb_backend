class MessageButtonLabel < ApplicationRecord
  has_many :instagram_user_message_button_labels
  has_many :instagram_users, through: :instagram_user_message_button_labels
  belongs_to :message_button
end
