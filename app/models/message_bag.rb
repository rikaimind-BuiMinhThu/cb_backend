class MessageBag < ApplicationRecord
  belongs_to :message_group
  has_many :messages, dependent: :destroy
end
