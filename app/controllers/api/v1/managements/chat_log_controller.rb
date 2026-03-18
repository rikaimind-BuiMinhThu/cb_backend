class Api::V1::Managements::ChatLogController < ApplicationController
  def index
    return render json: {code: 2, message: "No permission"} unless ["admin_deel", "admin_client"].include?(current_user.role)
    begin
      scenarios = Scenario.where(chatbot_id: params[:bot_id])
      cloned_scenarios = []
      scenarios.each do |scenario|
        cloned_scenario = Scenario.new
        cloned_scenario.attributes = scenario.attributes.slice(*scenario.attribute_names)
        cloned_scenario.save
        cloned_scenarios << cloned_scenario
      end
      if(params[:sc_id].present?)
        scenarios = scenarios.where(id: params[:sc_id])
      end
      scenario_user_responses = ScenarioUserResponse.select(:scenario_id, :user_input_id, 'MAX(updated_at) as newest')
                                        .where(scenario_id: scenarios.map(&:id))
                                        .group(:scenario_id, :user_input_id)
                                        .order('newest DESC')
      if(params[:date].present?)
        scenario_user_responses = scenario_user_responses.where('DATE(created_at) = ? ',params[:date].to_date)
      end
      if(params[:start_date].present?)
        scenario_user_responses = scenario_user_responses.where('DATE(created_at) >= ? ',params[:start_date].to_date)
      end
      if(params[:end_date].present?)
        scenario_user_responses = scenario_user_responses.where('DATE(created_at) <= ? ',params[:end_date].to_date)
      end

      grouped_responses = ChatLog.new(scenario_user_responses).get_grouped_response

      render json: { code: 1, scenarios: cloned_scenarios, chats: grouped_responses }
    rescue Exception => e
      return render json: { code: 2, message: e }
    end
  end

  def show
    return render json: {code: 2, message: "No permission"} unless ["admin_deel", "admin_client"].include?(current_user.role)
    if(params[:sc_id].blank? || params[:user_id].blank?)
      return render json: { code: 2, message: "Missing scenario_id or user_id" }
    end
    begin
      scenario_user_responses = ScenarioUserResponse.where(scenario_id: params[:sc_id], user_input_id: params[:user_id])
                                .order('created_at ASC')
      if(params[:start_date].present?)
        scenario_user_responses = scenario_user_responses.where('DATE(created_at) >= ? ',params[:start_date].to_date)
      end
      if(params[:end_date].present?)
        scenario_user_responses = scenario_user_responses.where('DATE(created_at) <= ? ',params[:end_date].to_date)
      end
      render json: { code: 1, conversations: scenario_user_responses }
    rescue Exception => e
      return render json: { code: 2, message: e }
    end
  end

  def statistic
    # Case 1: statistic cho 1 scenario (giữ behavior cũ)
    if params[:sc_id].present?
      statistic_instance = ScenarioUserResponses::Statistic.new(
        scenario_id: params[:sc_id],
        start_date: params[:start_date],
        end_date: params[:end_date]
      )

      statistics = statistic_instance.stats
      overall = statistic_instance.overall

      return render json: { code: 1, statistic: statistics, overall: overall }
    end

    # Case 2: statistic cho nhiều scenario theo bot_id
    if params[:bot_id].present?
      scenarios = Scenario.where(chatbot_id: params[:bot_id])

      if scenarios.blank?
        return render json: {
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
          start_date: params[:start_date],
          end_date: params[:end_date]
        )

        scenario_stats = statistic_instance.stats || []
        scenario_overall = statistic_instance.overall || {}

        # Gộp statistic theo msg_id
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

        # Gộp overall
        entry_count = scenario_overall['entry_count'] || scenario_overall[:entry_count] || 0
        form_completed_count = scenario_overall['form_completed_count'] || scenario_overall[:form_completed_count] || 0
        pgs_cv_count = scenario_overall['pgs_cv_count'] || scenario_overall[:pgs_cv_count] || 0
        impression_count = scenario_overall['impression_count'] || scenario_overall[:impression_count] || 0

        total_entry_count += entry_count
        total_form_completed_count += form_completed_count
        total_pgs_cv_count += pgs_cv_count
        total_impression_count += impression_count
      end

      # Tính lại completion_rate cho từng msg_id sau khi gộp
      statistics = aggregated_stats_by_msg.values.map do |row|
        appear_count = row['appear_count']
        complete_count = row['complete_count']
        completion_rate = appear_count > 0 ? ((complete_count.to_f / appear_count) * 100).round(2) : 0.0

        row.merge('completion_rate' => completion_rate)
      end

      # Tính overall sau khi gộp nhiều scenario
      overall = {
        entry_count: total_entry_count,
        form_completed_count: total_form_completed_count,
        form_completion_rate: total_entry_count > 0 ? ((total_form_completed_count.to_f / total_entry_count) * 100).round(2) : 0.0,
        pgs_cv_count: total_pgs_cv_count,
        pgs_cv_entry_rate: total_entry_count > 0 ? ((total_pgs_cv_count.to_f / total_entry_count) * 100).round(2) : 0.0,
        impression_count: total_impression_count
      }

      return render json: { code: 1, statistic: statistics, overall: overall }
    end

    render json: { code: 2, message: 'Missing scenario_id or bot_id', statistic: [], overall: {} }
  rescue => e
    render json: { code: 2, message: e.message, statistic: [], overall: {} }
  end

  private

  def parse_date(date_str)
    Date.parse(date_str) rescue nil
  end
end
