class Api::V1::Managements::ChatbotsController < ApplicationController

  def index
    return render json: {code: 2, message: "No permission"} if current_user.client?
    chatbots = Chatbot.all if current_user.admin_deel?
    chatbots = Chatbot.where(user_id: current_user.id) if current_user.admin_client?
    total = chatbots.length
    chatbots = chatbots.page(params[:page]).per(10)
    render json: {code: 1, data: chatbots, total: total}
  end

  def create
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    chatbot = Chatbot.new(chatbot_params)
    chatbot.user = current_user
    chatbot.status = :off
    return render json: {code: 1, data: chatbot} if chatbot.save
    render json: {code: 2, message: chatbot.errors.full_messages[0]}
  end

  private

  def chatbot_params
    params.require(:chatbot).permit(:title, :subtitle, :design_type,
      :main_color, :status, :icon, :bot_name)
  end
end



