class Api::V1::Analytics::ScenarioCountsController < ApplicationController
  skip_before_action :permision, only: :update
  skip_before_action :verify_authenticity_token, only: :update

  def show
    scenario = Scenario.select(:id, :pc_count, :tablet_count, :smartphone_count, :pc_conversion_count, :tablet_conversion_count,
                              :smartphone_conversion_count, :pc_open_chatbot_window_count, :tablet_open_chatbot_window_count, 
                              :smartphone_open_chatbot_window_count)
                      .find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find scenario"} if scenario.blank?
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    # return render json: {code: 2, data: "No permission"} if current_user.admin_client? && chatbot.user_chatbots.where(role: [:bot_admin, :editor, :reader]).pluck(:user_id).exclude?(current_user.id)
    render json: {code: 1, data: scenario}
  end

  def update
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find scenario"} if scenario.blank?
    scenario_data = params[:scenario_data]
    list_scenario_data = ["pc", "tablet", "smartphone", "pc_conversion", "tablet_conversion", "smartphone_conversion",
                          "pc_open_chatbot_window", "tablet_open_chatbot_window", "smartphone_open_chatbot_window"]
    return render json: {code: 2, message: "Invalid scenario data"} if list_scenario_data.exclude?(scenario_data)
    # this will become scenario.{scenario_data}_count = scenario.{scenario_data}_count + 1
    scenario.send("#{scenario_data}_count=".to_sym, scenario.send("#{scenario_data}_count".to_sym) + 1)
    return render json: {code: 1, message: "Success"} if scenario.save
    render json: {code: 2, message: scenario.errors.full_messages}
  end
end
