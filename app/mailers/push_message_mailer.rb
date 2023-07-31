class PushMessageMailer < ApplicationMailer
  def send_email(email, subject, content)
    @email = email
    to = email
    @content = content
    mail(to: to, subject: subject)
  end
end
