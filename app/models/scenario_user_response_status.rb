class ScenarioUserResponseStatus < ApplicationRecord
  belongs_to :scenario

  enum status: {finished: 1, un_finished: 0}

  def self.completed_count(scenario_id:, start_date: nil, end_date: nil) 
    between(start_date, end_date)
      .where(scenario_id: scenario_id, status: :finished)
      .distinct
      .count(:user_input_id)
  end

  scope :between, ->(start_date, end_date) do
    return all unless start_date || end_date

    if start_date && end_date
      where(created_at: start_date..end_date)
    elsif start_date
      where('created_at >= ?', start_date)
    else
      where('created_at <= ?', end_date)
    end
  end
end