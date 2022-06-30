class MessageGroup < ApplicationRecord
  has_many :message_bags, dependent: :destroy
  belongs_to :user
end
