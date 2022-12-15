class Api::V1::Analytics::ScenarioCountsController < ApplicationController
  skip_before_action :permision, only: :update
  skip_before_action :verify_authenticity_token, only: :update

  def show
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    @scenario = Scenario.includes(:analytic_scenarios)
                        .find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find scenario"} if @scenario.blank?
    @analytic_scenarios = @scenario.analytic_scenarios

    begin_date = params[:begin_date].to_date
    end_date = params[:end_date].to_date
    q = {created_at_lteq: end_date.end_of_day, created_at_gteq: begin_date.beginning_of_day}
    @analytic_scenarios = @analytic_scenarios.ransack(q).result
    # return render json: {code: 2, data: "No permission"} if current_user.admin_client? && chatbot.user_chatbots.where(role: [:bot_admin, :editor, :reader]).pluck(:user_id).exclude?(current_user.id)
    # render json: {code: 1, data: scenario}
    urls = ScenarioPage.where(scenario: @scenario).group(:url).pluck(:url)
    @scenario_pages = []
    list_scenario_pages = ScenarioPage.where(scenario: @scenario).ransack(q).result
    urls.each do |url|
      num_of_cv = list_scenario_pages.select("count(*) as num_of_cv_count")
                                     .num_of_cv.where(url: url)
      num_of_start = list_scenario_pages.select("count(*) as num_of_start_count")
                                        .num_of_start.where(url: url)
      @scenario_pages.push({url: url, num_of_cv: num_of_cv[0].num_of_cv_count, num_of_start: num_of_start[0].num_of_start_count})
    end
  end

  def update
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find scenario"} if scenario.blank?
    analytic_scenario_data = params[:scenario_data]
    list_analytic_scenario_data = ["pc", "tablet", "smartphone", "pc_conversion", "tablet_conversion", "smartphone_conversion",
                                   "pc_open_chatbot_window", "tablet_open_chatbot_window", "smartphone_open_chatbot_window",
                                   "pc_close_chatbot_window", "tablet_close_chatbot_window", "smartphone_close_chatbot_window"]
    return render json: {code: 2, message: "Invalid scenario data"} if list_analytic_scenario_data.exclude?(analytic_scenario_data)
    analytic_scenario = AnalyticScenario.new(type_of_analytic: analytic_scenario_data,
                                             scenario: scenario)
    return render json: {code: 1, message: "Success"} if analytic_scenario.save
    render json: {code: 2, message: analytic_scenario.errors.full_messages}
  end
end
