class AnalyticScenario < ApplicationRecord
  belongs_to :scenario

  enum type_of_analytic: {pc: 0, tablet: 1, smartphone: 2, pc_conversion: 3, tablet_conversion: 4, smartphone_conversion: 5, pc_open_chatbot_window: 6, tablet_open_chatbot_window: 7, smartphone_open_chatbot_window: 8, pc_close_chatbot_window: 9, tablet_close_chatbot_window: 10, smartphone_close_chatbot_window: 11}

  validates :type_of_analytic, presence: true

  scope :count_conversion_by_begin_date_and_end_date, -> begin_date, end_date {
    where("type_of_analytic in (?)", [3, 4, 5]) # all conversation
    scope = scope.where("created_at >= ?", begin_date.beginning_of_day) if begin_date.present?
    scope = scope.where("created_at <= ?", end_date.end_of_day) if end_date.present?
    scope
  }
end
