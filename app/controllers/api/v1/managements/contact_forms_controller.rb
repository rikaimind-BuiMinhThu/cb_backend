class Api::V1::Managements::ContactFormsController < ApplicationController
  skip_before_action :permision, only: :send_inquiry
  skip_before_action :verify_authenticity_token, only: :send_inquiry

  EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP

  def send_inquiry
    email_settings = inquiry_params[:email_settings] || {}
    fields = inquiry_params[:fields] || {}
    chatbot_id = inquiry_params[:chatbot_id]

    send_to_user = ActiveModel::Type::Boolean.new.cast(email_settings[:send_to_user])
    send_to_staff = ActiveModel::Type::Boolean.new.cast(email_settings[:send_to_staff])

    return render json: { code: 2, message: "Email settings are disabled" } if !send_to_user && !send_to_staff

    if fields[:name].blank? || fields[:email].blank? || fields[:content].blank?
      return render json: { code: 2, message: "Required fields are missing" }
    end

    unless EMAIL_REGEX.match?(fields[:email].to_s)
      return render json: { code: 2, message: "Invalid user email" }
    end

    if send_to_user
      unless template_belongs_to_chatbot?(email_settings[:user_email_id], chatbot_id)
        return render json: { code: 2, message: "User email template is required" }
      end
    end

    if send_to_staff
      unless template_belongs_to_chatbot?(email_settings[:staff_email_id], chatbot_id)
        return render json: { code: 2, message: "Staff email template is required" }
      end
    end

    payload = {
      chatbot_id: chatbot_id,
      scenario_id: inquiry_params[:scenario_id],
      form_template: inquiry_params[:form_template],
      fields: fields.to_h,
      email_settings: email_settings.to_h
    }

    ContactFormMailJob.perform_async(payload.as_json)

    render json: { code: 1, message: "Success" }, status: :accepted
  rescue StandardError => e
    Rails.logger.error(e)
    e.backtrace&.each { |line| Rails.logger.error(line) }
    render json: { code: 2, message: e.message }
  end

  private

  def template_belongs_to_chatbot?(email_id, chatbot_id)
    return false if email_id.blank? || chatbot_id.blank?

    Email.exists?(id: email_id, chatbot_id: chatbot_id)
  end

  def inquiry_params
    params.permit(
      :chatbot_id,
      :scenario_id,
      :form_template,
      fields: [
        :name,
        :email,
        :phone,
        :inquiry_type,
        :order_number,
        :product_name,
        :content
      ],
      email_settings: [
        :send_to_user,
        :send_to_staff,
        :user_email_id,
        :staff_email_id
      ]
    )
  end
end
