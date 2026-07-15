class EmailMailer < ApplicationMailer
  def send_email(email, client_email, variables, reply_to: nil)
    @email = email
    @variables = (variables || {}).with_indifferent_access
    to = [replace_var(@email.to)] + @email.email_ccs.pluck(:to)
    bcc = @email.email_bccs.pluck(:to)
    @content = replace_var(@email.content)

    mail_options = {
      to: to,
      bcc: bcc,
      subject: replace_var(@email.subject)
    }

    if client_email.present?
      mail_options[:delivery_method_options] = {
        user_name: client_email.email,
        password: client_email.password
      }
    end

    effective_reply_to = reply_to.presence || @email.reply_to
    mail_options[:reply_to] = replace_var(effective_reply_to) if effective_reply_to.present?

    mail(mail_options)
  end

  def replace_var(content)
    return content if content.blank?

    content = content.dup
    content.scan(/\{\{(.*?)\}\}/).flatten.each do |varia|
      content.gsub!("{{#{varia}}}", @variables[varia].to_s) if @variables[varia].present?
    end
    content
  end
end
