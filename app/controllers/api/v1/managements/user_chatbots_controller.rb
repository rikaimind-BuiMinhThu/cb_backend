class Api::V1::Managements::UserChatbotsController < ApplicationController
  before_action :check_chatbot, only: [:index, :create]
  before_action :find_user_chatbot, only: [:update, :destroy]
  before_action :check_bot_admin, only: [:create, :update, :destroy]

  def index
    return render json: {code: 2, message: "No permission"} unless UserChatbot.find_by(user_id: current_user.id, chatbot_id: params[:chatbot_id]).present?
    @user_chatbots = @chatbot.user_chatbots
  end

  def create
    user = User.find_by(email: params[:user_chatbot][:email])
    return render json: {code: 2, message: "Cannot find user"} if user.blank?
    user_chatbot = UserChatbot.new(user: user, chatbot_id: params[:user_chatbot][:chatbot_id], role: params[:user_chatbot][:role])
    return render json: {code: 1, data: user_chatbot} if user_chatbot.save
    render json: {code: 2, data: user_chatbot.errors.full_messages[0]}
  end

  def update
    return render json: {code: 2, message: "Don't update"} if @user_chatbot.bot_admin? && @user_chatbot.chatbot.user_id == @user_chatbot.user_id
    return render json: {code: 1, data: @user_chatbot} if @user_chatbot.update(role: params[:user_chatbot][:role])
    render json: {code: 2, data: @user_chatbot.errors.full_messages[0]}
  end

  def destroy
    return render json: {code: 2, message: "Don't delete"} if @user_chatbot.bot_admin? && @user_chatbot.chatbot.user_id == @user_chatbot.user_id
    return render json: {code: 1, data: @user_chatbot} if @user_chatbot.destroy
    render json: {code: 2, data: @user_chatbot.errors.full_messages[0]}
  end

  private

  def check_chatbot
    @chatbot = Chatbot.find_by(id: params[:chatbot_id]) if params[:chatbot_id].present?
    @chatbot = Chatbot.find_by(id: params[:user_chatbot][:chatbot_id]) if params[:user_chatbot].present? && params[:user_chatbot][:chatbot_id].present?
    return render json: {code: 2, message: "Chatbot not found"} if @chatbot.blank?
  end

  def find_user_chatbot
    @user_chatbot = UserChatbot.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find subuser"} if @user_chatbot.blank?
  end

  def check_bot_admin
    @current_user_chatbot = @user_chatbot.chatbot.user_chatbots.find_by(id: current_user.id) if @user_chatbot.present?
    @current_user_chatbot = @chatbot.user_chatbots.find_by(id: current_user.id) if @chatbot.present?
    return render json: {code: 2, message: "Something went wrong"} if @current_user_chatbot.blank?
    return render json: {code: 2, message: "No permission"} unless @current_user_chatbot.bot_admin?
  end
end



