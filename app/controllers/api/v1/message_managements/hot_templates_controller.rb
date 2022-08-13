class Api::V1::MessageManagements::HotTemplatesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    hot_templates = HotTemplate.all
    render json: {code: 1, data: hot_templates}
  end

  def create
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel?
    ActiveRecord::Base.transaction do
      HotTemplate.all.destroy_all
      hot_templates_params[:hot_templates].each do |hot_templates_param|
        HotTemplate.create!(hot_templates_param)
      end
    end
    render json: {code: 1, data: "create success"}
  rescue StandardError => error
    Rails.logger.error(error)
    error.backtrace.each do |line|
      Rails.logger.error(line)
    end
    return render json: {code: 2, message: error}
  end

  private

  def hot_templates_params
    params.permit(hot_templates: [:title, :description, :message_group_id])
  end
end
