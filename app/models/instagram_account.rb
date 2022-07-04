class InstagramAccount < ApplicationRecord
  belongs_to :user
  belongs_to :dm_bag, class_name: "MessageBag", optional: true
  belongs_to :post_comment_bag, class_name: "MessageBag", optional: true
  belongs_to :story_comment_bag, class_name: "MessageBag", optional: true
  belongs_to :live_comment_bag, class_name: "MessageBag", optional: true
  has_many :ice_breakers, dependent: :destroy
  has_many :persistent_menus, dependent: :destroy

  validates :user_id, presence: true, uniqueness: true
  validates :ig_id, presence: true, uniqueness: true
end
