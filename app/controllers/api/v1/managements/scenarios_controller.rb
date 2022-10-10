class Api::V1::Managements::ScenariosController < ApplicationController
  before_action :check_chatbot_present

  def index
    scenarios = Scenario.where(chatbot_id: params[:chatbot_id])
    total = scenarios.length
    scenarios = scenarios.page(params[:page])
    render json: {code: 1, data: scenarios, total: total}
  end

  def show
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"} if scenario.blank?
    render json: {code: 1, data: scenario}
  end

  def create
    scenario = Scenario.new(scenario_params)
    scenario.chatbot_id = params[:chatbot_id]
    ActiveRecord::Base.transaction do
      scenario.save!
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, data: scenario}
  end

  def update
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"} if scenario.blank?
    ActiveRecord::Base.transaction do
      scenario.update!(scenario_params)
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, data: scenario}
  end

  def destroy
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"} if scenario.blank?
    ActiveRecord::Base.transaction do
      scenario.destroy!
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, message: "Success"}
  end

  def detail_conversation
    @scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"} if @scenario.blank?
  end

  def conversation
    @scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"} if @scenario.blank?
    ActiveRecord::Base.transaction do
      @scenario.update!(conversation: JSON.generate(params[:conversation].as_json)) if params[:conversation].present?
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
  end

  def duplicate
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"} if scenario.blank?
    scenario_dup = scenario.dup
    if Scenario.find_by(name: scenario.name + " (1)",
                        chatbot_id: params[:chatbot_id]).present?
      index = 1
      loop do
        index += 1
        temp_message = Scenario.find_by(name: scenario.name + " (#{index})",
                                chatbot_id: params[:chatbot_id])
        break if temp_message.blank?
      end
      scenario_dup.name = scenario.name + " (#{index})"
    else
      scenario_dup.name = scenario.name + " (1)"
    end
    ActiveRecord::Base.transaction do
      scenario_dup.save!
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, data: scenario}
  end

  private

  def scenario_params
    params.require(:scenario).permit(:name)
  end

  def check_chatbot_present
    return render json: {code: 2, message: "Chatbot not found"} if Chatbot.find_by(id: params[:chatbot_id]).blank?
    user_chatbot = UserChatbot.find_by(user_id: current_user.id, chatbot_id: params[:chatbot_id])
    return render json: {code: 2, message: "No permission"} if user_chatbot.blank? || user_chatbot.reader?
  end
end
