class ChatbotUsage < ApplicationRecord
  belongs_to :instagram_account
  belongs_to :instagram_user
  has_many :chatbot_usage_groups, dependent: :destroy

  enum usage_type: {dm_received: 0, dm_sent: 1, post_comment_received: 2, post_comment_sent: 3, story_comment_received: 4, story_comment_sent: 5, live_comment_received: 6, live_comment_sent: 7}

  scope :search_by_begin_date_and_end_date, -> begin_date, end_date {
    scope = all
    scope = scope.where("created_at >= ?", begin_date) if begin_date.present?
    scope = scope.where("created_at <= ?", end_date) if end_date.present?
    scope
  }

end
