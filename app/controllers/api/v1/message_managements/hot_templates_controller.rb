class Api::V1::MessageManagements::HotTemplatesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    hot_templates = HotTemplate.joins(:message_group).select("hot_templates.*, message_groups.group_name")
    render json: {code: 1, data: hot_templates}
  end

  def create
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel?
    ActiveRecord::Base.transaction do
      hot_template = HotTemplate.create!(hot_template_params)
    end
    render json: {code: 1, data: "Success!"}
  rescue StandardError => error
    Rails.logger.error(error)
    error.backtrace.each do |line|
      Rails.logger.error(line)
    end
    return render json: {code: 2, message: error}
  end

  def update
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel?
    hot_template = HotTemplate.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find hot template"} if hot_template.blank?
    ActiveRecord::Base.transaction do
      hot_template.update!(hot_template_params)
    end
    render json: {code: 1, data: hot_template}
  rescue StandardError => error
    Rails.logger.error(error)
    error.backtrace.each do |line|
      Rails.logger.error(line)
    end
    return render json: {code: 2, message: error}
  end

  def destroy
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel?
    hot_template = HotTemplate.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find hot template"} if hot_template.blank?
    if hot_template.destroy
      render json: {code: 1, message: "Success!"}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  private

  def hot_template_params
    params.require(:hot_template).permit(:title, :description, :message_group_id)
  end
end
