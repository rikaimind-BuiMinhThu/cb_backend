class MessageGroup < ApplicationRecord
  has_many :message_bags, dependent: :destroy
  has_many :hot_templates, dependent: :destroy
  has_many :chatbot_usage_groups
  belongs_to :user

  validates :group_name, presence: true, uniqueness: true
end
