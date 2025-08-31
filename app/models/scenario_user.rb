class ScenarioUser < ApplicationRecord
  belongs_to :scenario

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

  def self.entry_count(scenario_id:, start_date: nil, end_date: nil)
    between(start_date, end_date)
      .where(scenario_id: scenario_id)
      .sum(:entry_count)
  end
end
