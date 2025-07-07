module ScenarioUserResponses
  class Statistic
    def initialize(scenario_id:, start_date: nil, end_date: nil)
      @scenario_id = scenario_id
      @start_date = parse_date(start_date)&.beginning_of_day
      @end_date = parse_date(end_date)&.end_of_day
    end

    def call
      logs = ScenarioUserResponse.where(scenario_id: @scenario_id)
      
      logs = logs.where(created_at: @start_date..@end_date) if @start_date && @end_date
      logs = logs.where('created_at >= ?', @start_date) if @start_date && !@end_date
      logs = logs.where('created_at <= ?', @end_date)   if @end_date && !@start_date

      access_counts = logs.group(:message_id).count
      pass_counts = logs.select(:message_id, :user_input_id).distinct.group(:message_id).count

      access_counts.map do |msg_id, access_count|
        {
          msg_id: msg_id,
          access_count: access_count,
          pass_count: pass_counts[msg_id] || 0
        }
      end
    end

    private

    def parse_date(date_str)
      DateTime.parse(date_str.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
