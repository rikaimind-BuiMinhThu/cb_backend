class Api::V1::Analytics::ScenarioPagesController < ApplicationController
  skip_before_action :permision, only: :create
  skip_before_action :verify_authenticity_token, only: :create

  def create
    scenario_page = ScenarioPage.new(scenario_page_params)
    return render json: {code: 1, message: "Success"} if scenario_page.save
    render json: {code: 2, message: scenario_page.errors.full_messages}
  end

  def show
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find scenario"} if scenario.blank?
    urls = ScenarioPage.where(scenario: scenario).group(:url).pluck(:url)
    data = []
    urls.each do |url|
      num_of_cv = ScenarioPage.num_of_cv.where(scenario: scenario, url: url).select("count(*) as num_of_cv_count")
      num_of_start = ScenarioPage.num_of_start.where(scenario: scenario, url: url).select("count(*) as num_of_start_count")
      data.push({url: url, num_of_cv: num_of_cv[0].num_of_cv_count, num_of_start: num_of_start[0].num_of_start_count})
    end
    render json: {code: 1, data: data}
  end

  private

  def scenario_page_params
    params.require(:scenario_page).permit(:url, :scenario_id, :num_type)
  end
end
