class InstagramAccount < ApplicationRecord
  belongs_to :user
  # belongs_to :dm_bag, class_name: "MessageBag", optional: true
  belongs_to :post_comment_bag, class_name: "MessageBag", optional: true
  belongs_to :story_comment_bag, class_name: "MessageBag", optional: true
  belongs_to :live_comment_bag, class_name: "MessageBag", optional: true
  belongs_to :default_reply_bag, class_name: "MessageBag", optional: true
  has_many :ice_breakers, dependent: :destroy
  has_many :persistent_menus, dependent: :destroy
  has_many :instagram_users, dependent: :destroy
  has_many :chatbot_usages, dependent: :destroy
  has_many :keyword_settings, dependent: :destroy

  validates :user_id, presence: true, uniqueness: true
  validates :ig_id, presence: true, uniqueness: true

  enum post_comment_bag_status: {off: 0, direct_message: 1, keyword: 2}, _prefix: :post_comment_bag_status
  enum story_comment_bag_status: {off: 0, direct_message: 1, keyword: 2}, _prefix: :story_comment_bag_status
  enum live_comment_bag_status: {off: 0, direct_message: 1, keyword: 2}, _prefix: :live_comment_bag_status
end
