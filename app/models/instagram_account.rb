class InstagramAccount < ApplicationRecord
  belongs_to :user
  belongs_to :dm_bag, class_name: "MessageBag", optional: true
  belongs_to :post_comment_bag, class_name: "MessageBag", optional: true
  belongs_to :story_comment_bag, class_name: "MessageBag", optional: true
  belongs_to :live_comment_bag, class_name: "MessageBag", optional: true
end
