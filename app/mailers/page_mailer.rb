class PageMailer < ApplicationMailer
  def request_support_email(user, instagram_user)
    @user = user
    @instagram_user = instagram_user
    mail(to: @user.email, subject: "Sample Email")
  end
end
