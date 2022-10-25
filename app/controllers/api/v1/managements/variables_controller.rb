class Api::V1::Managements::VariablesController < ApplicationController
  before_action :check_chatbot_present

  def index
    variables = Variable.where(chatbot_id: params[:chatbot_id])
    total = variables.length
    variables = variables.page(params[:page]) if params[:page] != 'all'
    render json: {code: 1, data: variables, total: total}
  end

  def show
    variable = Variable.find_by(id: params[:id])
    return render json: {code: 2, message: "Variable not found"} if variable.blank?
    render json: {code: 1, data: variable}
  end

  def create
    variable = Variable.new(variable_params)
    variable.chatbot_id = params[:chatbot_id]
    ActiveRecord::Base.transaction do
      variable.save!
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, data: variable}
  end

  def update
    variable = Variable.find_by(id: params[:id])
    return render json: {code: 2, message: "Variable not found"} if variable.blank?
    ActiveRecord::Base.transaction do
      variable.update!(variable_params)
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, data: variable}
  end

  def destroy
    variable = Variable.find_by(id: params[:id])
    return render json: {code: 2, message: "Variable not found"} if variable.blank?
    ActiveRecord::Base.transaction do
      variable.destroy!
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, message: "Success"}
  end

  private

  def variable_params
    params.require(:variable).permit(:variable_name, :default_value)
  end

  def check_chatbot_present
    return render json: {code: 2, message: "Chatbot not found"} if Chatbot.find_by(id: params[:chatbot_id]).blank?
    user_chatbot = UserChatbot.find_by(user_id: current_user.id, chatbot_id: params[:chatbot_id])
    return render json: {code: 2, message: "No permission"} if user_chatbot.blank? || user_chatbot.reader?
  end
end
