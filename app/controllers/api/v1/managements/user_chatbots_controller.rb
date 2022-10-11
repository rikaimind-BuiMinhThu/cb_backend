class Api::V1::Managements::UserChatbotsController < ApplicationController
  def index
    return render json: {code: 2, message: "No permission"} unless UserChatbot.find_by(user_id: current_user.id, chatbot_id: params[:chatbot_id]).present? || current_user.admin_deel?
    chatbot = Chatbot.find_by(id: params[:chatbot_id])
    return render json: {code: 2, data: "Cannot find chatbot"} if chatbot.blank?
    @user_chatbots = chatbot.user_chatbots
  end

  def create
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    chatbot = Chatbot.where(id: params[:user_chatbot][:chatbot_id], user_id: current_user.id).first
    return render json: {code: 2, message: "Cannot find chatbot"} if chatbot.blank?
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? && chatbot.user_chatbots.bot_admin.find_by(user_id: current_user.id).present?
    user = User.find_by(id: params[:user_chatbot][:user_id])
    return render json: {code: 2, message: "Cannot find user"} if user.blank?
    return render json: {code: 2, message: "User email cannot be blank"} if user.email.blank?
    user_chatbot = UserChatbot.new(user: user, chatbot: chatbot, role: params[:user_chatbot][:role])
    return render json: {code: 1, data: user_chatbot} if user_chatbot.save
    render json: {code: 2, data: user_chatbot.errors.full_messages[0]}
  end

  def update
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    user_chatbot = UserChatbot.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find user_chatbot"} if user_chatbot.blank?
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? && user_chatbot.chatbot.user_chatbots.bot_admin.find_by(user_id: current_user.id).present?
    return render json: {code: 1, data: user_chatbot} if user_chatbot.update(role: params[:user_chatbot][:role])
    render json: {code: 2, data: user_chatbot.errors.full_messages[0]}
  end

  def destroy
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    user_chatbot = UserChatbot.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find user_chatbot"} if user_chatbot.blank?
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? && user_chatbot.chatbot.user_chatbots.bot_admin.find_by(user_id: current_user.id).present?
    return render json: {code: 1, data: user_chatbot} if user_chatbot.destroy
    render json: {code: 2, data: user_chatbot.errors.full_messages[0]}
  end
end



