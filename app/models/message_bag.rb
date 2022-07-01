class MessageBag < ApplicationRecord
  belongs_to :message_group
  has_many :messages, dependent: :destroy
  has_one :dm_bag_ig, class_name: "InstagramAccount", foreign_key: "dm_bag_id"
  has_one :post_comment_bag_ig, class_name: "InstagramAccount", foreign_key: "post_comment_bag_id"
  has_one :story_comment_bag_ig, class_name: "InstagramAccount", foreign_key: "story_comment_bag_id"
  has_one :live_comment_bag_ig, class_name: "InstagramAccount", foreign_key: "live_comment_bag_id"
end
