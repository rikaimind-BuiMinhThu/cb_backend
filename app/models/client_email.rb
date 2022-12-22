class ClientEmail < ApplicationRecord
  belongs_to :client, optional: true

  validates :email, presence: true, format: URI::MailTo::EMAIL_REGEXP
  validates :password, presence: true
end
