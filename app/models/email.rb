class Email < ApplicationRecord
  has_many :email_ccs, dependent: :destroy
  has_many :email_bccs, dependent: :destroy
  belongs_to :user
  belongs_to :chatbot

  validates :to, presence: true
  validates :email_template_name, presence: true
  validates :subject, presence: true
  validates :content, presence: true
end
