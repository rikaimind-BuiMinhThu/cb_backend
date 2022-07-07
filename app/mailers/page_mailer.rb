class PageMailer < ApplicationMailer
  def request_support_email(user)
    @user = user
    mail(to: @user.email, subject: "Sample Email")
  end
end
