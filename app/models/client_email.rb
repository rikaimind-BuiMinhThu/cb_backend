class ClientEmail < ApplicationRecord
  belongs_to :client

  encrypts :password, deterministic: true

  validates :email, presence: true, format: URI::MailTo::EMAIL_REGEXP
  validates :password, presence: true
  validates :client, presence: true, uniqueness: true
end
