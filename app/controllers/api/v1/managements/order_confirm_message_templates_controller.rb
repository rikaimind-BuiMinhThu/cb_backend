class Api::V1::Managements::OrderConfirmMessageTemplatesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_admin_deel!, except: [:index, :show]
  before_action :set_order_confirm_message_template, only: [:show, :update, :destroy]

  def index
    templates = OrderConfirmMessageTemplate
      .select(:id, :name, :updated_at)
      .order(updated_at: :desc)
    render json: { code: 1, data: templates }
  end

  def show
    render json: { code: 1, data: serialize_template(@order_confirm_message_template) }
  end

  def create
    template = OrderConfirmMessageTemplate.new(order_confirm_message_template_params)
    template.created_by_id = current_user.id
    template.config_hash = default_config_hash if template.config.blank?
    template.save!
    render json: { code: 1, data: serialize_template(template) }
  rescue ActiveRecord::RecordInvalid => error
    render json: { code: 2, message: error.record.errors.full_messages.join(", ") }
  rescue StandardError => error
    Rails.logger.error(error)
    render json: { code: 2, message: error.message }, status: 500
  end

  def update
    @order_confirm_message_template.name = template_name_param if template_name_param.present?
    if params[:config].present?
      @order_confirm_message_template.config_hash = params[:config].as_json
    end
    @order_confirm_message_template.save!
    render json: { code: 1, data: serialize_template(@order_confirm_message_template) }
  rescue ActiveRecord::RecordInvalid => error
    render json: { code: 2, message: error.record.errors.full_messages.join(", ") }
  rescue StandardError => error
    Rails.logger.error(error)
    render json: { code: 2, message: error.message }, status: 500
  end

  def destroy
    @order_confirm_message_template.destroy!
    render json: { code: 1, message: "Success" }
  rescue StandardError => error
    Rails.logger.error(error)
    render json: { code: 2, message: error.message }, status: 500
  end

  private

  def require_admin_deel!
    return if current_user.admin_deel?

    render json: { code: 2, message: "No permission" } and return
  end

  def set_order_confirm_message_template
    @order_confirm_message_template = OrderConfirmMessageTemplate.find_by(id: params[:id])
    return if @order_confirm_message_template.present?

    render json: { code: 2, message: "Template not found" }, status: 404 and return
  end

  def order_confirm_message_template_params
    params.require(:order_confirm_message_template).permit(:name)
  end

  def template_name_param
    params.dig(:order_confirm_message_template, :name)
  end

  def serialize_template(template)
    {
      id: template.id,
      name: template.name,
      config: template.config_hash,
      updated_at: template.updated_at,
      created_at: template.created_at
    }
  end

  def default_config_hash
    {
      "lp_preset" => "ecforce",
      "preview_root_selector" => "#preview-view",
      "retry" => { "maxRetry" => 20, "delay" => 500 },
      "error_message" => "入力エラーが発生しています。修正の上、再度お試しください。",
      "scroll_auto" => false
    }
  end
end
