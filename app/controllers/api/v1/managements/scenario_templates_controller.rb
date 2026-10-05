class Api::V1::Managements::ScenarioTemplatesController < ApplicationController
  include ScenarioContentPersistence

  skip_before_action :verify_authenticity_token
  before_action :require_admin_deel!, except: [:index]
  before_action :set_scenario_template, only: [:show, :destroy, :detail_conversation, :conversation]

  def index
    templates = ScenarioTemplate.select(:id, :name, :scenario_type, :updated_at).order(updated_at: :desc)
    render json: { code: 1, data: templates }
  end

  def show
    render json: { code: 1, data: @scenario_template }
  end

  def create
    template = ScenarioTemplate.new(scenario_template_params)
    template.created_by_id = current_user.id
    template.scenario_type = params[:scenario_type] || "payment" if template.scenario_type.blank?
    template.save!
    render json: { code: 1, data: template }
  rescue ActiveRecord::RecordInvalid => error
    render json: { code: 2, message: error.record.errors.full_messages.join(", ") }
  rescue StandardError => error
    Rails.logger.error(error)
    render json: { code: 2, message: error.message }, status: 500
  end

  def destroy
    @scenario_template.destroy!
    render json: { code: 1, message: "Success" }
  rescue StandardError => error
    Rails.logger.error(error)
    render json: { code: 2, message: error.message }, status: 500
  end

  def detail_conversation
    @landing_page_product_url = @scenario_template.landing_page_product_url
  end

  def conversation
    ActiveRecord::Base.transaction do
      @scenario_template.name = params[:scenario_name] if params[:scenario_name].present?
      apply_scenario_content_params!(@scenario_template)
    end
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

  def set_scenario_template
    @scenario_template = ScenarioTemplate.find_by(id: params[:id])
    render(json: { code: 2, message: "Template not found" }, status: 404) and return if @scenario_template.blank?
  end

  def scenario_template_params
    params.require(:scenario_template).permit(:name, :scenario_type)
  end
end
