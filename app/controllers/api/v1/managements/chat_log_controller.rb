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
    scenario_id = params[:sc_id]
    return render json: { code: 2, message: 'Missing scenario_id', statistic: [] } if scenario_id.blank?

    date_start = parse_date(params[:start_date])&.beginning_of_day
    date_end   = parse_date(params[:end_date])&.end_of_day

    logs = ScenarioUserResponse.where(scenario_id: scenario_id)
    logs = logs.where(created_at: date_start..date_end) if date_start && date_end
    logs = logs.where('created_at >= ?', date_start)   if date_start && !date_end
    logs = logs.where('created_at <= ?', date_end)     if date_end && !date_start

    access_counts = logs.group(:message_id).count
    pass_counts = logs.select(:message_id, :user_input_id).distinct.group(:message_id).count

    result = access_counts.map do |msg_id, access_count|
      {
        msg_id: msg_id,
        access_count: access_count,
        pass_count: pass_counts[msg_id] || 0
      }
    end

    render json: { code: 1, statistic: result }

  rescue => e
    render json: { code: 2, message: e.message, statistic: [] }
  end

  private

  def parse_date(date_str)
    Date.parse(date_str) rescue nil
  end
end
