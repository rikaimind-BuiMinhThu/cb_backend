class Api::V1::Managements::EmailsController < ApplicationController
  skip_before_action :permision, only: :send_email
  skip_before_action :verify_authenticity_token, only: :send_email

  def index
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    @chatbot = Chatbot.find_by(id: params[:chatbot_id])
    return render json: {code: 2, data: "Cannot find chatbot"} if @chatbot.blank?
    return render json: {code: 2, data: "No permission"} if current_user.admin_client? && @chatbot.user_chatbots.pluck(:user_id).include?(current_user.id)
    page = params[:page] || 1
    @emails = Email.where(chatbot_id: @chatbot.id).includes(:email_ccs, :email_bccs)
    if current_user.admin_client?
      user_ids = current_user.client.users.pluck(:id)
      @emails = @emails.where(user_id: user_ids)
    end
    @total = @emails.length
    @emails = @emails.page(page) if page != 'all'
  end

  def create
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    chatbot = Chatbot.find_by(id: params[:email][:chatbot_id])
    return render json: {code: 2, data: "Cannot find chatbot"} if chatbot.blank?
    return render json: {code: 2, data: "No permission"} if current_user.admin_client? && chatbot.user_chatbots.where(role: [:bot_admin, :editor]).pluck(:user_id).exclude?(current_user.id)
    ActiveRecord::Base.transaction do
      email = Email.create!(email_params)
      if params[:email][:cc].present?
        params[:email][:cc].each do |cc|
          EmailCc.create!(email: email, to: cc)
        end
      end

      if params[:email][:bcc].present?
        params[:email][:bcc].each do |bcc|
          EmailBcc.create!(email: email, to: bcc)
        end
      end
    rescue StandardError => error
      Rails.logger.debug(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, message: "Success"}
  end

  def show
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    email = Email.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find email"} if email.blank?
    return render json: {code: 2, data: "No permission"} if current_user.admin_client? && email.chatbot.user_chatbots.pluck(:user_id).include?(current_user.id)
    render json: {code: 1, data: {email: email, email_cc: email.email_ccs, email_bcc: email.email_bccs}}
  end

  def update
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    email = Email.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find email"} if email.blank?
    return render json: {code: 2, data: "No permission"} if current_user.admin_client? && email.chatbot.user_chatbots.where(role: [:bot_admin, :editor]).pluck(:user_id).exclude?(current_user.id)
    chatbot = Chatbot.find_by(id: params[:email][:chatbot_id])
    return render json: {code: 2, data: "Cannot find chatbot"} if chatbot.blank?
    return render json: {code: 2, data: "No permission"} if current_user.admin_client? && chatbot.user_chatbots.where(role: [:bot_admin, :editor]).pluck(:user_id).exclude?(current_user.id)
    ActiveRecord::Base.transaction do
      email.update!(email_params)
      email.email_ccs.each do |email_cc|
        email_cc.destroy!
      end
      email.email_bccs.each do |email_bcc|
        email_bcc.destroy!
      end
      if params[:email][:cc].present?
        params[:email][:cc].each do |cc|
          EmailCc.create!(email: email, to: cc)
        end
      end

      if params[:email][:bcc].present?
        params[:email][:bcc].each do |bcc|
          EmailBcc.create!(email: email, to: bcc)
        end
      end
    rescue StandardError => error
      Rails.logger.debug(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, message: "Success"}
  end

  def destroy
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    email = Email.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find email"} if email.blank?
    return render json: {code: 2, data: "No permission"} if current_user.admin_client? && email.chatbot.user_chatbots.where(role: [:bot_admin, :editor]).pluck(:user_id).exclude?(current_user.id)
    ActiveRecord::Base.transaction do
      email.email_ccs.each do |email_cc|
        email_cc.destroy!
      end
      email.email_bccs.each do |email_bcc|
        email_bcc.destroy!
      end
      email.destroy!
    rescue StandardError => error
      Rails.logger.debug(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, message: "Success"}
  end

  def duplicate
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    email = Email.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find email"} if email.blank?
    return render json: {code: 2, data: "No permission"} if current_user.admin_client? && email.chatbot.user_chatbots.where(role: [:bot_admin, :editor]).pluck(:user_id).exclude?(current_user.id)
    ActiveRecord::Base.transaction do
      new_email = email.dup
      new_email.user = current_user
      new_email.save!
      email.email_ccs.each do |email_cc|
        EmailCc.create!(email: new_email, to: email_cc.to)
      end
      email.email_bccs.each do |email_bcc|
        EmailBcc.create!(email: new_email, to: email_bcc.to)
      end
    rescue StandardError => error
      Rails.logger.debug(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, message: "Success"}
  end

  def get_list_emails_by_chatbot
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    chatbot = Chatbot.find_by(id: params[:chatbot_id])
    return render json: {code: 2, data: "Cannot find chatbot"} if chatbot.blank?
    return render json: {code: 2, data: "No permission"} if current_user.admin_client? && chatbot.user_chatbots.pluck(:user_id).include?(current_user.id)
    emails = Email.select(:id, :email_template_name)
                   .where(chatbot_id: chatbot.id)
    render json: {code: 1, data: emails}
  end

  def send_email
    # return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    email = Email.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find email"} if email.blank?
    # return render json: {code: 2, data: "No permission"} if current_user.admin_client? && email.chatbot.user_chatbots.where(role: [:bot_admin, :editor]).pluck(:user_id).exclude?(current_user.id)
    client_email_id = email.chatbot.user&.client.id
    client_email = ClientEmail.find_by(id: client_email_id)
    return render json: {code: 2, data: "Cannot find client email"} if client_email.blank?
    # return render json: {code: 2, data: "No permission"} if current_user.admin_client? && client_email.client_id == current_user.client_id
    EmailMailer.send_email(email, client_email, params[:variables]).deliver
  end

  private

  def email_params
    params.require(:email).merge!(user_id: current_user.id).permit(:email_template_name, :sender_name, :to, :reply_to, :subject, :content, :user_id, :chatbot_id)
  end
end
