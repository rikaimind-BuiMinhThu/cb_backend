class Conversion < ApplicationRecord
  belongs_to :instagram_user
  belongs_to :message_bag

  enum user_source: {dm: 0, post_comment: 1, story_comment: 2, live_comment: 3}
end
