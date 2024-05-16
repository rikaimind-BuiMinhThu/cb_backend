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
      render json: { code: 1, scenarios: cloned_scenarios, chats: scenario_user_responses }
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
end
