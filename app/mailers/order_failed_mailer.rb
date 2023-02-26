class OrderFailedMailer < ApplicationMailer
  def send_email(email, client_email, data)
    @email = email
    to = email
    bcc = client_email
    @content = data
    mail(to: to, bcc: bcc, subject: 'Order Failed!!!')
  end
end
