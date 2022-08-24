class InstagramUser < ApplicationRecord
  has_many :instagram_user_labels
  has_many :custom_items
  has_many :chatbot_usages
  has_many :conversions
  has_many :supporting_users
  belongs_to :instagram_account
  belongs_to :pending_message, class_name: Message.name, foreign_key: :pending_message_id, optional: true

  enum status: {archive: 0, lead: 1, progression: 2, completion: 3}
  enum start_chatbot_in: {dm: 0, post_comment: 1, story_comment: 2, live_comment: 3}

  validates :email, allow_blank: true, format: URI::MailTo::EMAIL_REGEXP
  # validates :phone_number, allow_blank: true, format: { with: /\A[0]\d{10}\z/ }
  validates :phone_number, allow_blank: true, format: { with: /\A[0](([0-9]{9}\z)|([0-9]{2}-[0-9]{3}-[0-9]{4}\z)|([0-9]{1}-[0-9]{4}-[0-9]{4}\z)|([0-9]{10}\z)|([0-9]{2}-[0-9]{4}-[0-9]{4}\z))/ }
end
