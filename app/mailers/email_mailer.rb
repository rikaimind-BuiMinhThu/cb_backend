class EmailMailer < ApplicationMailer
  def send_email(email, variables)
    @email = email
    @variables = variables
    to = [replace_var(@email.to)] + Email.first.email_ccs.pluck(:to)
    bcc = Email.first.email_bccs.pluck(:to)
    @content = replace_var(@email.content)
    mail(to: to, bcc: bcc, subject: replace_var(@email.subject))
  end

  def replace_var(content)
    content.scan(/\{\{(.*?)\}\}/).flatten.each do |varia|
      content.gsub!("{{#{varia}}}", @variables[varia]) if @variables[varia].present?
    end
    content
  end
end
