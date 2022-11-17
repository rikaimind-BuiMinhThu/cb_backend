class Api::V1::Managements::HistoryClickUrlsController < ApplicationController
  def index
    chatbot = find_chatbot
    return if chatbot.blank?
    history_click_urls = chatbot.history_click_urls.select(:id, :num_of_click, :origin_url, :shorten_code)
    return render json: {code: 1, data: history_click_urls}
  end

  def create
    chatbot = find_chatbot
    return if chatbot.blank?
    history_click_url = HistoryClickUrl.new(history_click_url_params)
    history_click_url.chatbot = chatbot
    return render json: {code: 1, message: history_click_url} if history_click_url.save
    render json: {code: 2, message: history_click_url.errors.full_messages}
  end

  def show
    history_click_url = find_history_click_url
    return if history_click_url.blank?
    history_click_url.num_of_click += 1
    history_click_url.save
    render json: {code: 1, origin_url: history_click_url.origin_url}
  end

  def update
    history_click_url = find_history_click_url(true)
    return if history_click_url.blank?
    return render json: {code: 1, message: history_click_url} if history_click_url.update(history_click_url_params)
    render json: {code: 2, message: history_click_url.errors.full_messages}
  end

  def destroy
    history_click_url = find_history_click_url(true)
    return if history_click_url.blank?
    return render json: {code: 2, data: "Cannot find push message"} if history_click_url.blank?
    return render json: {code: 2, data: "No permission"} if current_user.admin_client? && history_click_url.chatbot.user_chatbots.where(roles: [:bot_admin, :editor]).pluck(:user_id).include?(current_user.id)
    return render json: {code: 1, message: history_click_url} if history_click_url.destroy
    render json: {code: 2, message: history_click_url.errors.full_messages}

  end

  private

  def history_click_url_params
    params.require(:history_click_url).permit(:origin_url)
  end

  def find_chatbot
    render json: {code: 2, message: "Not have permission"} and return unless current_user.admin_deel? || current_user.admin_client?
    if params[:history_click_url].present? && params[:history_click_url][:chatbot_id].present?
      chatbot_id = params[:history_click_url][:chatbot_id]
    else
      chatbot_id = params[:chatbot_id] || params[:id]
    end
    chatbot = Chatbot.find_by(id: chatbot_id)
    render json: {code: 2, message: "Not found chatbot"} and return if chatbot.blank?
    user_chatbot = chatbot.user_chatbots.find_by(chatbot_id: chatbot_id, user: current_user)
    render json: {code: 2, message: "Not have permission"} and return if current_user.admin_client? && user_chatbot.blank?
    chatbot
  end

  def find_history_click_url(editor_permission = false)
    render json: {code: 2, message: "Not have permission"} and return unless current_user.admin_deel? || current_user.admin_client?
    history_click_url = editor_permission.present? ? HistoryClickUrl.find_by(id: params[:id]) : HistoryClickUrl.find_by(shorten_code: params[:id])
    render json: {code: 2, message: "Not found history click url"} and return if history_click_url.blank?
    return history_click_url if editor_permission.blank?
    chatbot = history_click_url.chatbot
    render json: {code: 2, message: "Not found chatbot"} and return if chatbot.blank?
    user_chatbots = chatbot.user_chatbots.where(user: current_user).where(role: [:bot_admin, :editor])
    render json: {code: 2, message: "Not have permission"} and return if current_user.admin_client? && user_chatbot.blank?
    history_click_url
  end
end
