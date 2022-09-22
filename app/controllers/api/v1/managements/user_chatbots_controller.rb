class Api::V1::Managements::UserChatbotsController < ApplicationController
  def create
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    chatbot = Chatbot.where(id: params[:user_chatbot][:chatbot_id], user_id: current_user.id).first
    return render json: {code: 2, message: "Cannot find chatbot"} if chatbot.blank?
    user = User.find_by(id: params[:user_chatbot][:user_id])
    return render json: {code: 2, message: "Cannot find chatbot"} if chatbot.blank?
    user_chatbot = UserChatbot.new(user: user, chatbot: chatbot, role: params[:user_chatbot][:role])
    return render json: {code: 1, data: user_chatbot} if user_chatbot.save
    render json: {code: 2, data: user_chatbot.errors.full_messages[0]}
  end
end



