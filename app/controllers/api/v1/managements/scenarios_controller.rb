class Api::V1::Managements::ScenariosController < ApplicationController
  skip_before_action :permision, only: [:preview, :get_scenario_selected]
  skip_before_action :verify_authenticity_token, only: [:preview, :get_scenario_selected]
  before_action :check_chatbot_present, except: [:preview, :get_scenario_selected]

  SCAN_REGEX = /\{\{(.*?)\}\}/

  def index
    scenarios = Scenario.where(chatbot_id: params[:chatbot_id])
    total = scenarios.length
    scenarios = scenarios.page(params[:page])
    render json: {code: 1, data: scenarios, total: total, scenario_selected: @chatbot.scenario_selected}
  end

  def show
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"} if scenario.blank?
    render json: {code: 1, data: scenario}
  end

  def preview
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"} if scenario.blank?
    scenario_conversation = scenario.conversation
    # variables = Variable.where(variable_name: scenario_conversation.scan(/\{\{(.*?)\}\}/).flatten).each do |variable|
    #   scenario_conversation.gsub!("{{#{variable.variable_name}}}", variable.default_value)
    # end
    variables = Variable.select(:variable_name, :default_value)
                        .where(variable_name: scenario_conversation.scan(/\{\{(.*?)\}\}/).flatten)

    chatbot = Chatbot.find_by(id: scenario.chatbot_id)

    render json: {
      code: 1, data: {
        id: scenario.id,
        name: scenario.name,
        chatbot_id: scenario.chatbot_id,
        conversation: JSON.parse(scenario_conversation),
        created_at: scenario.created_at,
        updated_at: scenario.updated_at
      }, variables: variables, chatbot: chatbot
    }
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
      @scenario.update!(conversation: JSON.generate(params[:conversation].as_json), name: params[:scenario_name]) if params[:conversation].present?
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

  def get_all
    scenarios = Scenario.select(:id, :name)
                        .where(chatbot_id: params[:chatbot_id])
    render json: {code: 1, data: scenarios}
  end

  def get_scenario_selected
    chatbot = Chatbot.find_by(id: params[:chatbot_id])
    return render json: {code: 2, message: "Chatbot not found"} if chatbot.blank?
    scenario = Scenario.select(:id, :name)
                       .find_by(id: chatbot.scenario_selected)
    render json: {code: 1, data: scenario}
  end

  def get_list_scenario_by_client
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    chatbot_ids = Chatbot.where(user_id: params[:user_id]).pluck(:id)
    render json: {code: 2, message: "No data"} if chatbot_ids.length == 0
    scenarios = Scenario.select(:id, :name)
                        .where("chatbot_id in (?)", chatbot_ids)
    render json: {code: 1, data: scenarios}
  end

  private

  def scenario_params
    params.require(:scenario).permit(:name)
  end

  def check_chatbot_present
    @chatbot = Chatbot.find_by(id: params[:chatbot_id])
    return render json: {code: 2, message: "Chatbot not found"} if @chatbot.blank?
    user_chatbot = UserChatbot.find_by(user_id: current_user.id, chatbot_id: params[:chatbot_id])
    return render json: {code: 2, message: "No permission"} if (user_chatbot.blank? || user_chatbot.reader?)
  end
end
