class Api::V1::Analytics::ScenarioPagesController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  def create
    scenario_page = ScenarioPage.new(scenario_page_params)
    return render json: {code: 1, message: "Success"} if scenario_page.save
    render json: {code: 2, message: scenario_page.errors.full_messages}
  end

  private

  def scenario_page_params
    params.require(:scenario_page).permit(:url, :scenario_id, :num_type)
  end
end
