class Message < ApplicationRecord
  belongs_to :message_bag
  has_many :quick_replies
  has_many :message_buttons

  enum message_type: {msg: 0, img: 1, img_msg: 2, past_post: 3, profile_msg: 4}

  mount_base64_uploader :img_value, ImageMessageUploader

  validates :message_bag, presence: true
  # validates :message_value, presence: true
  validates :message_type, presence: true
end
