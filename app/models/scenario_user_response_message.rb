class ScenarioUserResponseMessage < ApplicationRecord
  belongs_to :scenario

  enum submit_type: { appear: 0, error: 1, add: 2, retry: 3 }

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

  def self.stats_for(scenario_id:, start_date: nil, end_date: nil)
    logs = where(scenario_id: scenario_id).between(start_date, end_date)

    message_ids = logs.distinct.pluck(:message_id)

    message_ids.map do |msg_id|
      subset = logs.where(message_id: msg_id)

      appear_count    = subset.appear.count
      error_count     = subset.error.count
      complete_count  = subset.add.count
      retry_count     = subset.retry.count
      completion_rate = appear_count > 0 ? (complete_count.to_f / appear_count * 100).round(2) : 0

      {
        msg_id: msg_id,
        appear_count: appear_count,
        error_count: error_count,
        complete_count: complete_count,
        retry_count: retry_count,
        completion_rate: completion_rate
      }
    end
  end
end
