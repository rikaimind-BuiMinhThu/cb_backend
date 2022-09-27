class EmailCc < ApplicationRecord
  belongs_to :email

  validates :to, presence: true, format: URI::MailTo::EMAIL_REGEXP
end
