# frozen_string_literal: true

owner = User.find_by!(email: "client-admin@local.test")
chatbot = Chatbot.find_by!(user: owner, bot_name: "Local Demo Bot")

Variable.find_or_create_by!(chatbot: chatbot, variable_name: "customer_name") do |variable|
  variable.default_value = "ゲスト"
end

Variable.find_or_create_by!(chatbot: chatbot, variable_name: "order_note") do |variable|
  variable.default_value = ""
end

payment_method_variable = Variable.find_or_create_by!(chatbot: chatbot, variable_name: "payment_method") do |variable|
  variable.default_value = "credit_card"
end

settlement_variable = Variable.find_or_create_by!(chatbot: chatbot, variable_name: "settlement_payment_method") do |variable|
  variable.default_value = "credit_card"
end

shipping_variable = Variable.find_or_create_by!(chatbot: chatbot, variable_name: "shipping_prefecture") do |variable|
  variable.default_value = "東京都"
end

email = Email.find_or_initialize_by(chatbot: chatbot, email_template_name: "Local Order Confirm")
email.assign_attributes(
  user: owner,
  to: "customer@example.com",
  subject: "ご注文ありがとうございます",
  content: "<p>{{customer_name}} 様<br>ご注文を受け付けました。</p>"
)
email.save!

sms_template = SmsTemplate.find_or_initialize_by(chatbot: chatbot, name: "Local SMS Thanks")
sms_template.assign_attributes(
  user: owner,
  content: "ご注文ありがとうございます。Local Demo Botより。"
)
sms_template.save!

PushMessage.find_or_create_by!(chatbot: chatbot, title: "Local Email Push") do |push|
  push.sending_method = :email
  push.email = email
  push.started_at = 1.day.ago
  push.last_message_datetime_since = 24
  push.subscribe_status = :subscribe
end

PushMessage.find_or_create_by!(chatbot: chatbot, title: "Local SMS Push") do |push|
  push.sending_method = :sms
  push.sms_template = sms_template
  push.started_at = 2.days.ago
  push.last_message_datetime_since = 48
  push.subscribe_status = :subscribe
end

UserFile.find_or_create_by!(user: owner, file_url: "https://example.com/seed/local-demo.pdf") do |file|
  file.file_type = "application/pdf"
end

gateway = PaymentGateway.find_or_create_by!(user: owner, gateway_name: "Local GMO Test") do |gw|
  gw.payment_agency = :gmo
  gw.mode = :test
  gw.shop_id = "seed-shop-id"
  gw.shop_pass = "seed-shop-pass"
  gw.is_default = :yes
end

SpecifyPaymentVariable.find_or_create_by!(chatbot: chatbot, variable_value: "credit_card") do |row|
  row.payment_gateway = gateway
end

SpecifyPaymentVariable.find_or_create_by!(chatbot: chatbot, variable_value: "np_deferred") do |row|
  row.payment_gateway = gateway
end

SettlementFeeVariable.find_or_create_by!(chatbot: chatbot, variable_value: "credit_card") do |row|
  row.commission = 0
end

SettlementFeeVariable.find_or_create_by!(chatbot: chatbot, variable_value: "np_deferred") do |row|
  row.commission = 330
end

[
  { name: "東京都", prefecture_jis_code: "13", prefecture_name_kana: "トウキョウト" },
  { name: "大阪府", prefecture_jis_code: "27", prefecture_name_kana: "オオサカフ" },
  { name: "神奈川県", prefecture_jis_code: "14", prefecture_name_kana: "カナガワケン" }
].each do |attrs|
  Prefecture.find_or_create_by!(name: attrs[:name]) do |prefecture|
    prefecture.prefecture_jis_code = attrs[:prefecture_jis_code]
    prefecture.prefecture_name_kana = attrs[:prefecture_name_kana]
  end
end

[
  ["東京都", 500],
  ["大阪府", 700],
  ["神奈川県", 550]
].each do |prefecture_name, amount|
  prefecture = Prefecture.find_by!(name: prefecture_name)
  ShippingFeeVariable.find_or_create_by!(chatbot: chatbot, prefecture: prefecture) do |row|
    row.amount = amount
  end
end

np_settlement = chatbot.np_value_settlements.find_or_initialize_by(
  np_settlement_min_value: 0,
  np_settlement_max_value: 50_000
)
np_settlement.np_settlement_fee_value = 300
np_settlement.save!

chatbot.assign_attributes(
  can_specify_payment: :yes,
  specify_payment_variable: payment_method_variable,
  need_paid_settlement_fee: :paid,
  settlement_fee_variable: settlement_variable,
  need_paid_shipping_fee: :paid,
  shipping_fee_variable: shipping_variable,
  need_np_deferred_payment: :yes,
  np_maximum_amount: 50_000,
  np_invoice_included: :not_include
)
chatbot.save!

HistoryClickUrl.find_or_create_by!(chatbot: chatbot, origin_url: "https://example.com/lp/payment") do |click|
  click.num_of_click = 12
end
