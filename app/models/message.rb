class Message < ApplicationRecord
  belongs_to :message_bag
  has_many :quick_replies

  enum status: {:msg, :img, :img_msg, :past_post, :profile_msg}
end
