class Api::V1::Managements::SmsTemplatesController < ApplicationController
  before_action :require_admin
  before_action :find_chatbot

  def index
    if current_user.admin_client? && @chatbot.user_chatbots.pluck(:user_id).exclude?(current_user.id)
      return render json: { code: 2,
                            message: 'No permission' }
    end

    page = params[:page] || 1
    sms_templates = @chatbot.sms_templates
    total = sms_templates.length
    list = sms_templates.page(page).per(10)

    render json: { code: 1, data: list, total: total }
  end

  def create
    ActiveRecord::Base.transaction do
      sms_template = SmsTemplate.new(sms_template_params)
      sms_template.chatbot = @chatbot
      sms_template.user = current_user
      sms_template.save!
      render json: { code: 1, data: sms_template }
    rescue StandardError => e
      Rails.logger.error(e)
      e.backtrace.each do |line|
        Rails.logger.error(line)
      end
      return render json: { code: 2, message: e }
    end
  end

  def show
    template = SmsTemplate.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"} if template.blank?
    render json: {code: 1, data: template}
  end

  def update
    template = SmsTemplate.find_by(id: params[:id])
    ActiveRecord::Base.transaction do
      template.update!(sms_template_params)
      render json: {code: 1, message: "Success", data: template}
    rescue StandardError => error
      Rails.logger.debug(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      return render json: {code: 2, message: "Cannot update"}
    end
  end

  def destroy
    template = SmsTemplate.find_by(id: params[:id])
    ActiveRecord::Base.transaction do
      template.destroy!
      render json: {code: 1, message: "Success"}
    rescue StandardError => error
      Rails.logger.debug(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      return render json: {code: 2, message: "Cannot remove"}
    end
  end

  private

  def sms_template_params
    params.require(:sms_template).permit(:name, :content)
  end

  def find_chatbot
    @chatbot = Chatbot.find_by(id: params[:chatbot_id])
    return render json: { code: 2, message: 'Cannot find chatbot' } if @chatbot.blank?
  end

  def require_admin
    unless current_user.admin_deel? || current_user.admin_client?
      return render json: { code: 2,
                            message: 'No permission' }
    end
  end
end
