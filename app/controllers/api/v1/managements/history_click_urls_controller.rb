class Api::V1::Managements::HistoryClickUrlsController < ApplicationController
  skip_before_action :permision, only: [:create, :show]
  skip_before_action :verify_authenticity_token, only: [:create, :show]

  def index
    return if check_permission.blank?
    history_click_urls = HistoryClickUrl.select(:id, :num_of_click, :origin_url, :shorten_code)
                                        .where(chatbot_id: params[:chatbot_id])
    return render json: {code: 1, data: history_click_urls}
  end

  def create
    history_click_url = if history_click_url_params[:origin_url].include?(Settings.api.shorten_url)
      HistoryClickUrl.find_by(shorten_code: history_click_url_params[:origin_url].gsub(Settings.api.shorten_url, '').gsub('/', '').split('?')[0], chatbot_id: params[:chatbot_id])
    else
      HistoryClickUrl.find_by(origin_url: history_click_url_params[:origin_url], chatbot_id: params[:chatbot_id])
    end
    if history_click_url.blank?
      history_click_url = HistoryClickUrl.new(history_click_url_params)
      history_click_url.chatbot_id = params[:chatbot_id]
      history_click_url.num_of_click = 0
    end
    history_click_url.num_of_click += 1
    return render json: {code: 1, message: history_click_url} if history_click_url.save
    render json: {code: 2, message: history_click_url.errors.full_messages}
  end

  def show
    history_click_url = find_history_click_url
    return if history_click_url.blank?
    render json: {code: 1, origin_url: history_click_url.origin_url}
  end

  def destroy
    return if check_permission.blank?
    history_click_url = find_history_click_url(true)
    return if history_click_url.blank?
    return render json: {code: 1, message: history_click_url} if history_click_url.destroy
    render json: {code: 2, message: history_click_url.errors.full_messages}
  end

  private

  def history_click_url_params
    params.require(:history_click_url).permit(:origin_url)
  end

  def check_permission
    render json: {code: 2, message: "Not have permission"} and return unless current_user.admin_deel?
    true
  end

  def find_history_click_url(is_delete = false)
    history_click_url = is_delete.present? ? HistoryClickUrl.find_by(id: params[:id], chatbot_id: params[:chatbot_id]) : HistoryClickUrl.find_by(shorten_code: params[:id] , chatbot_id: params[:chatbot_id])
    render json: {code: 2, message: "Not found history click url"} and return if history_click_url.blank?
    history_click_url
  end
end
