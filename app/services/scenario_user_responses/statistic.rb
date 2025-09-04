module ScenarioUserResponses
  class Statistic
    def initialize(scenario_id:, start_date: nil, end_date: nil)
      @scenario_id = scenario_id
      @start_date = parse_date(start_date)&.beginning_of_day
      @end_date = parse_date(end_date)&.end_of_day
    end

    def stats
      stats = ScenarioUserResponseMessage.stats_for(
        scenario_id: @scenario_id,
        start_date: @start_date,
        end_date: @end_date
      );
    end

    def overall
      entry_count = ScenarioUserResponse.entry_count_for(
        scenario_id: @scenario_id,
        start_date: @start_date,
        end_date: @end_date
      )

      form_completed_count = ScenarioUserResponseStatus.completed_count(
        scenario_id: @scenario_id,
        start_date: @start_date,
        end_date: @end_date
      )

      pgs_cv_count = Order.pgs_cv_count(
        scenario_id: @scenario_id,
        start_date: @start_date,
        end_date: @end_date
      )

      impression_count = ScenarioUser.entry_count(
        scenario_id: @scenario_id,
        start_date: @start_date,
        end_date: @end_date
      )

      {
        entry_count: entry_count,
        form_completed_count: form_completed_count,
        form_completion_rate: entry_count > 0 ? ((form_completed_count.to_f / entry_count) * 100).round(2) : 0.0,
        pgs_cv_count: pgs_cv_count,
        pgs_cv_entry_rate: entry_count > 0 ? ((pgs_cv_count.to_f / entry_count) * 100).round(2) : 0.0,
        impression_count: impression_count
      }
    end

    private

    def parse_date(date_str)
      DateTime.parse(date_str.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
