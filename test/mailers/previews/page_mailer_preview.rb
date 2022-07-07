# Preview all emails at http://localhost:3000/rails/mailers/page_mailer
class PageMailerPreview < ActionMailer::Preview
  def request_support_email_preview
    PageMailer.request_support_email(User.first)
  end
end
