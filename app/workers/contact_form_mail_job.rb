class ContactFormMailJob
  include Sidekiq::Worker

  def perform(payload)
    data = payload.with_indifferent_access
    email_settings = (data[:email_settings] || {}).with_indifferent_access
    fields = (data[:fields] || {}).with_indifferent_access
    chatbot_id = data[:chatbot_id]
    variables = build_variables(fields, data[:form_template])
    client_email = resolve_client_email(chatbot_id)

    if ActiveModel::Type::Boolean.new.cast(email_settings[:send_to_user])
      email = find_template(email_settings[:user_email_id], chatbot_id)
      raise "User email template not found" if email.blank?

      EmailMailer.send_email(email, client_email, variables).deliver
    end

    if ActiveModel::Type::Boolean.new.cast(email_settings[:send_to_staff])
      email = find_template(email_settings[:staff_email_id], chatbot_id)
      raise "Staff email template not found" if email.blank?

      EmailMailer.send_email(
        email,
        client_email,
        variables,
        reply_to: fields[:email]
      ).deliver
    end
  rescue StandardError => e
    Rails.logger.error("ContactFormMailJob failed: #{e.message}")
    e.backtrace&.each { |line| Rails.logger.error(line) }
    raise
  end

  private

  def build_variables(fields, form_template)
    {
      "name" => fields[:name].to_s,
      "user_name" => fields[:name].to_s,
      "email" => fields[:email].to_s,
      "phone" => fields[:phone].to_s,
      "inquiry_type" => fields[:inquiry_type].to_s,
      "order_number" => fields[:order_number].to_s,
      "product_name" => fields[:product_name].to_s,
      "content" => fields[:content].to_s,
      "form_template" => form_template.to_s
    }
  end

  def find_template(email_id, chatbot_id)
    return nil if email_id.blank?

    Email.find_by(id: email_id, chatbot_id: chatbot_id)
  end

  def resolve_client_email(chatbot_id)
    chatbot = Chatbot.find_by(id: chatbot_id)
    return nil if chatbot.blank?

    chatbot.user&.client&.reply_smtp_credentials
  end
end
