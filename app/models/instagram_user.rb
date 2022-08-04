class InstagramUser < ApplicationRecord
  has_many :instagram_user_labels
  has_many :custom_items
  has_many :chatbot_usages
  belongs_to :instagram_account
  belongs_to :pending_message, class_name: Message.name, foreign_key: :pending_message_id, optional: true

  validates :email, allow_blank: true, format: URI::MailTo::EMAIL_REGEXP
  validates :phone_number, allow_blank: true, format: { with: /\A[0]\d{10}\z/ }
end
