class ContactFormMailer < ApplicationMailer
  FIELD_LABELS = {
    "name" => "お名前",
    "email" => "メールアドレス",
    "phone" => "電話番号",
    "inquiry_type" => "お問い合わせ種別",
    "order_number" => "注文番号",
    "product_name" => "商品名",
    "content" => "お問い合わせ内容"
  }.freeze

  def user_confirmation(to:, subject:, payload:, delivery_options: nil)
    @payload = payload.with_indifferent_access
    @fields = formatted_fields(@payload[:fields])
    mail_options = { to: to, subject: subject.presence || "お問い合わせを受け付けました" }
    mail_options[:delivery_method_options] = delivery_options if delivery_options.present?
    mail(mail_options)
  end

  def staff_notification(to:, subject:, payload:, delivery_options: nil)
    @payload = payload.with_indifferent_access
    @fields = formatted_fields(@payload[:fields])
    user_email = @payload.dig(:fields, :email).presence || @payload.dig(:fields, "email")
    mail_options = {
      to: to,
      subject: subject.presence || "【お問い合わせ】新規受付"
    }
    mail_options[:reply_to] = user_email if user_email.present?
    mail_options[:delivery_method_options] = delivery_options if delivery_options.present?
    mail(mail_options)
  end

  private

  def formatted_fields(fields)
    return [] if fields.blank?

    fields.to_h.filter_map do |key, value|
      next if value.blank?

      label = FIELD_LABELS[key.to_s] || key.to_s
      { label: label, value: value.to_s }
    end
  end
end
