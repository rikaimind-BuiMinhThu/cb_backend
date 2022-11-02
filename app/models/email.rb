class Email < ApplicationRecord
  has_many :email_ccs
  has_many :email_bccs
  belongs_to :user
  belongs_to :chatbot

  validates :to, presence: true, format: URI::MailTo::EMAIL_REGEXP
  validates :email_template_name, presence: true
  validates :sender_name
  validates :to, presence: true
  validates :reply_to
  validates :subject, presence: true
  validates :content, presence: true
end
