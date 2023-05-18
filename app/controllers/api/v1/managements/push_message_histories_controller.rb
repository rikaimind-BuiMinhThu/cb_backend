class Api::V1::Managements::PushMessageHistoriesController < ApplicationController
  def index
    chatbot = find_chatbot
    return if chatbot.blank?

    if params[:sent_time_from] && params[:sent_time_to]
      @push_message_histories = PushMessageHistory.where(chatbot_id: params[:chatbot_id]).where('sent_time BETWEEN ? AND ?',
                                                                                                params[:sent_time_from], params[:sent_time_to]).includes(:push_message)
    else
      @push_message_histories = PushMessageHistory.where(chatbot_id: params[:chatbot_id]).includes(:push_message)
    end
    @total = @push_message_histories.length
    @push_message_histories = @push_message_histories.page(params[:page]) if params[:page] != 'all'
    render json: { code: 1, data: @push_message_histories, total: @total }, include: [:push_message]
  end

  private

  def find_chatbot
    unless current_user.admin_deel? || current_user.admin_client?
      render json: { code: 2,
                     message: 'Not have permission' } and return
    end

    chatbot = Chatbot.find_by(id: params[:chatbot_id] || params[:id])
    render json: { code: 2, message: 'Not found chatbot' } and return if chatbot.blank?

    user_chatbot = chatbot.user_chatbots.find_by(chatbot_id: params[:chatbot_id], user: current_user)
    if current_user.admin_client? && user_chatbot.blank?
      render json: { code: 2,
                     message: 'Not have permission' } and return
    end

    chatbot
  end
end
