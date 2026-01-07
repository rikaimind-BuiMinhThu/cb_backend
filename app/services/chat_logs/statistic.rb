module ChatLogs
  class Statistic
    def initialize(sc_id:, bot_id:, start_date:, end_date:)
      @sc_id = sc_id
      @bot_id = bot_id
      @start_date = start_date
      @end_date = end_date
    end

    def call
      # Case 1: statistic cho 1 scenario (giữ behavior cũ)
      if @sc_id.present?
        return stats_for_single_scenario
      end

      # Case 2: statistic cho nhiều scenario theo bot_id
      if @bot_id.present?
        return stats_for_bot
      end

      { code: 2, message: 'Missing scenario_id or bot_id', statistic: [], overall: {} }
    rescue => e
      { code: 2, message: e.message, statistic: [], overall: {} }
    end

    private

    def stats_for_single_scenario
      statistic_instance = ScenarioUserResponses::Statistic.new(
        scenario_id: @sc_id,
        start_date: @start_date,
        end_date: @end_date
      )

      statistics = statistic_instance.stats
      overall = statistic_instance.overall

      { code: 1, statistic: statistics, overall: overall }
    end

    def stats_for_bot
      scenarios = Scenario.where(chatbot_id: @bot_id)

      if scenarios.blank?
        return {
          code: 1,
          statistic: [],
          overall: {
            entry_count: 0,
            form_completed_count: 0,
            form_completion_rate: 0.0,
            pgs_cv_count: 0,
            pgs_cv_entry_rate: 0.0,
            impression_count: 0
          }
        }
      end

      aggregated_stats_by_msg = {}
      total_entry_count = 0
      total_form_completed_count = 0
      total_pgs_cv_count = 0
      total_impression_count = 0

      scenarios.each do |scenario|
        statistic_instance = ScenarioUserResponses::Statistic.new(
          scenario_id: scenario.id,
          start_date: @start_date,
          end_date: @end_date
        )

        scenario_stats = statistic_instance.stats || []
        scenario_overall = statistic_instance.overall || {}

        aggregate_stats_for_scenario(aggregated_stats_by_msg, scenario_stats)
        aggregate_overall_for_scenario(
          scenario_overall,
          ->(entry) { total_entry_count += entry },
          ->(completed) { total_form_completed_count += completed },
          ->(pgs_cv) { total_pgs_cv_count += pgs_cv },
          ->(impressions) { total_impression_count += impressions }
        )
      end

      statistics = build_statistics_array(aggregated_stats_by_msg)

      overall = {
        entry_count: total_entry_count,
        form_completed_count: total_form_completed_count,
        form_completion_rate: total_entry_count > 0 ? ((total_form_completed_count.to_f / total_entry_count) * 100).round(2) : 0.0,
        pgs_cv_count: total_pgs_cv_count,
        pgs_cv_entry_rate: total_entry_count > 0 ? ((total_pgs_cv_count.to_f / total_entry_count) * 100).round(2) : 0.0,
        impression_count: total_impression_count
      }

      { code: 1, statistic: statistics, overall: overall }
    end

    def aggregate_stats_for_scenario(aggregated_stats_by_msg, scenario_stats)
      scenario_stats.each do |row|
        msg_id = row['msg_id'] || row[:msg_id]
        next if msg_id.nil?

        aggregated_stats_by_msg[msg_id] ||= {
          'msg_id' => msg_id,
          'appear_count' => 0,
          'error_count' => 0,
          'complete_count' => 0,
          'retry_count' => 0
        }

        agg = aggregated_stats_by_msg[msg_id]

        appear_count = row['appear_count'] || row[:appear_count] || 0
        error_count = row['error_count'] || row[:error_count] || 0
        complete_count = row['complete_count'] || row[:complete_count] || 0
        retry_count = row['retry_count'] || row[:retry_count] || 0

        agg['appear_count'] += appear_count
        agg['error_count'] += error_count
        agg['complete_count'] += complete_count
        agg['retry_count'] += retry_count
      end
    end

    def aggregate_overall_for_scenario(scenario_overall, entry_acc, completed_acc, pgs_cv_acc, impressions_acc)
      entry_count = scenario_overall['entry_count'] || scenario_overall[:entry_count] || 0
      form_completed_count = scenario_overall['form_completed_count'] || scenario_overall[:form_completed_count] || 0
      pgs_cv_count = scenario_overall['pgs_cv_count'] || scenario_overall[:pgs_cv_count] || 0
      impression_count = scenario_overall['impression_count'] || scenario_overall[:impression_count] || 0

      entry_acc.call(entry_count)
      completed_acc.call(form_completed_count)
      pgs_cv_acc.call(pgs_cv_count)
      impressions_acc.call(impression_count)
    end

    def build_statistics_array(aggregated_stats_by_msg)
      aggregated_stats_by_msg.values.map do |row|
        appear_count = row['appear_count']
        complete_count = row['complete_count']
        completion_rate = appear_count > 0 ? ((complete_count.to_f / appear_count) * 100).round(2) : 0.0

        row.merge('completion_rate' => completion_rate)
      end
    end
  end
end

