class MessageGroup < ApplicationRecord
  has_many :message_bags, dependent: :destroy
  has_many :message_bags, dependent: :destroy
  has_many :chatbot_usage_groups
  belongs_to :user
end
