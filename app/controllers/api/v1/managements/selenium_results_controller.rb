class Api::V1::Managements::SeleniumResultsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_lexica_staff

  def index
    outcome = Lexica::BotOrders.list(
      chatbot_id: requested_chatbot_id,
      client_id: listing_client_id,
      result: list_params[:result],
      path: list_params[:path],
      start_date: list_params[:start_date],
      end_date: list_params[:end_date],
      page: list_params[:page]
    )
    return render json: outcome[:error], status: :unprocessable_entity if outcome[:error]

    render json: { code: 1, data: outcome[:data], total: outcome[:total] }
  end

  def show
    row = find_row
    return render json: { code: 2, message: "not found" } if row.blank?

    render json: { code: 1, data: Lexica::BotOrders.detail_json(row) }
  end

  def screenshot
    row = find_row
    return render json: { code: 2, message: "not found" }, status: :not_found if row.blank? || !Lexica::BotOrders.screenshot_available?(row)

    send_data AmazonWebServices::RpaScreenshotS3.read(row.screenshot_path), type: "image/png", disposition: "inline"
  end

  def step_screenshot
    row = find_row
    key = Lexica::BotOrders.step_screenshot_key(row, list_params[:screenshot_path])
    return render json: { code: 2, message: "not found" }, status: :not_found if row.blank? || key.blank?

    send_data AmazonWebServices::RpaScreenshotS3.read(key), type: "image/png", disposition: "inline"
  end

  private

  def require_lexica_staff
    unless current_user&.admin_deel? || current_user&.admin_client?
      render json: { code: 2, message: "No permission" }
      return
    end
    return if lexica_client?

    render json: { code: 2, message: "not lexica" }, status: 403
  end

  def find_row
    Lexica::BotOrders.find_row(
      chatbot_id: requested_chatbot_id,
      client_id: listing_client_id,
      id: list_params[:id]
    )
  end

  def list_params
    params.permit(:result, :path, :start_date, :end_date, :page, :id, :screenshot_path, :chatbot_id, :bot_id)
  end

  def lexica_client?
    client&.lexica?
  end

  def client
    @client ||= if current_user.admin_deel?
      Chatbot.find_by(id: requested_chatbot_id)&.user&.client ||
        current_user.client
    else
      current_user.client
    end
  end

  def requested_chatbot_id
    list_params[:chatbot_id].presence || list_params[:bot_id].presence
  end

  def listing_client_id
    return client.id if client
    return current_user.client_id if requested_chatbot_id.blank? && current_user.admin_client?

    nil
  end
end
