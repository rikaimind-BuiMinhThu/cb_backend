class Conversion < ApplicationRecord
  belongs_to :instagram_user
  belongs_to :message_bag, optional: true

  enum user_source: {dm: 0, post_comment: 1, story_comment: 2, live_comment: 3}

  scope :search_by_begin_date_and_end_date, -> begin_date, end_date {
    scope = all
    scope = scope.where("conversion_at >= ?", begin_date.beginning_of_day) if begin_date.present?
    scope = scope.where("conversion_at <= ?", end_date.end_of_day) if end_date.present?
    scope
  }
end
