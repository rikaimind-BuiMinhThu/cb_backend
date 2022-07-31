class ChatbotUsage < ApplicationRecord
  belongs_to :instagram_account
  belongs_to :instagram_user

  enum usage_type: {dm_received: 0, dm_sent: 1, post_comment_received: 2, post_comment_sent: 3, story_comment_received: 4, story_comment_sent: 5, live_comment_received: 6, live_comment_sent: 7}
end
