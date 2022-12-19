class EmailMailer < ApplicationMailer
  def send_email(email)
    @email = email
    to = [@email.to] + Email.first.email_ccs.pluck(:to)
    bcc = Email.first.email_bccs.pluck(:to)
    mail(to: to, bcc: bcc, subject: @email.subject)
  end
end
