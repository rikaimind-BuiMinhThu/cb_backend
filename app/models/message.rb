class Message < ApplicationRecord
  belongs_to :message_bag
  has_many :quick_replies

  enum message_type: {msg: 0, img: 1, img_msg: 2, past_post: 3, profile_msg: 4}
end
