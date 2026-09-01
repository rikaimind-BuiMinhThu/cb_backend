# frozen_string_literal: true

# Development sample for 未来 (Mirai) Lexica. Idempotent. Does not change Local Dev.
# Does not enqueue LexicaScenarioJob.

PASSWORD = "Password123!"
CART_URL = "https://cart.mirai-japan.co.jp/"
SHOP_URL = "https://mirai-japan.co.jp/"
SAMPLE_PASSWORD = "Sample1234"

PROFILE_ANSWERS = {
  "user_name" => { "valueLeft" => "山田", "valueRight" => "太郎" }.to_json,
  "user_name_kana" => { "valueLeft" => "ヤマダ", "valueRight" => "タロウ" }.to_json,
  "zip_code_address" => {
    "value_post_code" => "1500001",
    "value_prefecture" => "東京都",
    "value_municipality" => "渋谷区神宮前",
    "value_address" => "1-1-1",
    "building_name" => "サンプルビル",
    "zip_code" => "150-0001",
    "prefecture" => "東京都",
    "city" => "渋谷区神宮前",
    "town" => "1-1-1"
  }.to_json,
  "phone_number" => "09012345678",
  "birth_date" => {
    "valueYear" => "1990",
    "valueMonth" => "1",
    "valueDay" => "15",
    "yyyy" => "1990",
    "mm" => "1",
    "dd" => "15"
  }.to_json
}.freeze

SystemSetting.lexica_max_chrome = 10

client = Client.find_or_initialize_by(name: "未来")
client.assign_attributes(
  url: SHOP_URL,
  shop_url: CART_URL,
  cart_system: :lexica,
  lexica_max_chrome: 5,
  status: :active,
  is_web: true,
  email: "mirai-admin@local.test",
  name_katakana: "ミライ"
)
client.save!

[
  { email: "mirai-admin@local.test", role: :admin_client, full_name: "未来 管理者" },
  { email: "mirai@local.test", role: :client, full_name: "未来 ユーザー" }
].each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.client = client
  user.role = attrs[:role]
  user.full_name = attrs[:full_name]
  user.phone_number = "00000000000"
  user.can_read = true
  user.can_write = true
  user.password = PASSWORD
  user.password_confirmation = PASSWORD
  user.save!
end

owner = User.find_by!(email: "mirai-admin@local.test")

chatbot = Chatbot.find_or_initialize_by(bot_name: "未来 レキシカ")
chatbot.assign_attributes(
  user: owner,
  title: "未来 レキシカ",
  subtitle: "レキシカ注文サンプル",
  design_type: :pop,
  status: :on,
  chat_body_version: "2.0"
)
chatbot.save!

[owner, User.find_by(email: "admin@local.test")].compact.each do |member|
  UserChatbot.find_or_create_by!(user: member, chatbot: chatbot) do |join|
    join.role = :bot_admin
  end
end

conversation = {
  messages: [],
  urlThanksPage: "",
  urlCartConfirmPage: "",
  isUsedCartConfirmPage: false,
  coupon: ""
}

scenario = Scenario.find_or_initialize_by(chatbot: chatbot, name: "未来 待ち")
scenario.assign_attributes(
  scenario_type: "payment",
  merchandise_id: "SAMPLE-SKU",
  landing_page_product_url: SHOP_URL,
  lexica_cart_url: CART_URL,
  order_result_mode: "wait",
  conversation: JSON.generate(conversation)
)
scenario.save!

chatbot.update!(scenario_selected: scenario.id)

gateway = PaymentGateway.find_or_initialize_by(user: owner, payment_agency: :zeus)
gateway.assign_attributes(
  gateway_name: "未来 ZEUS（サンプル）",
  mode: :test,
  token_js_url: "https://example.test/zeus/token.js",
  client_ip: "SAMPLECLIENTIP",
  ipcode: "SAMPLEIPCODE",
  is_default: :no
)
gateway.save!

upsert_response = lambda do |user_input_id, name, value|
  row = ScenarioUserResponse.find_or_initialize_by(
    scenario_id: scenario.id,
    user_input_id: user_input_id,
    data_input_name: name
  )
  row.value = value
  row.save!
end

now = Time.current

samples = [
  {
    user_input_id: "mirai-sample-running",
    result: :running,
    path: "first_time",
    payment: "credit",
    last_step_description: "待機中",
    last_step_no: 1,
    email: "running@example.test",
    end_time: nil,
    lexica_order_id: nil,
    error_kind: nil,
    error_message: nil,
    masked_pan: "************1111",
    card_expiry: "1228",
    card_holder: "TARO MIRAI",
    rpa_steps: [
      { "name" => "queued", "description" => "待機中" }
    ],
    answers: PROFILE_ANSWERS,
    with_password: false,
    cv: false,
    finished: false
  },
  {
    user_input_id: "mirai-sample-done",
    result: :done,
    path: "existing",
    payment: "gmo_atobarai",
    last_step_description: "完了を確認",
    last_step_no: 8,
    email: "done@example.test",
    end_time: now,
    lexica_order_id: "LEX-SAMPLE-001",
    error_kind: nil,
    error_message: nil,
    masked_pan: nil,
    card_expiry: nil,
    card_holder: nil,
    rpa_steps: [
      { "name" => "open_shop", "description" => "ショップを開く", "ok" => true, "url" => SHOP_URL },
      { "name" => "add_to_cart", "description" => "カートに入れる", "ok" => true, "url" => CART_URL },
      { "name" => "proceed_to_checkout", "description" => "レジへ", "ok" => true, "url" => CART_URL },
      { "name" => "auth_login", "description" => "ログイン", "ok" => true, "url" => CART_URL },
      { "name" => "payment_gmo_atobarai", "description" => "支払い", "ok" => true, "url" => CART_URL },
      { "name" => "fill_delivery", "description" => "お届け", "ok" => true, "url" => CART_URL },
      { "name" => "submit_order", "description" => "注文確定", "ok" => true, "url" => CART_URL },
      { "name" => "detect_result", "description" => "完了を確認", "ok" => true }
    ],
    answers: {},
    with_password: true,
    cv: true,
    finished: true
  },
  {
    user_input_id: "mirai-sample-error",
    result: :error,
    path: "new",
    payment: "cod",
    last_step_description: "同意して会員登録する",
    last_step_no: 3,
    email: "error@example.test",
    end_time: now,
    lexica_order_id: nil,
    error_kind: "rpa_error",
    error_message: "サンプル失敗（カートは実行していません）",
    masked_pan: nil,
    card_expiry: nil,
    card_holder: nil,
    rpa_steps: [
      { "name" => "auth_register", "description" => "会員登録", "ok" => true, "url" => CART_URL },
      { "name" => "fill_customer", "description" => "お客様情報", "ok" => true, "url" => CART_URL },
      { "name" => "submit_signup", "description" => "同意して会員登録する", "ok" => false, "error" => "既に会員" }
    ],
    answers: PROFILE_ANSWERS,
    with_password: true,
    cv: false,
    finished: false
  }
]

samples.each do |sample|
  row = ScenarioUserResponseSeleniumResult.find_or_initialize_by(
    user_input_id: sample[:user_input_id],
    scenario_id: scenario.id
  )
  row.assign_attributes(
    client_id: client.id,
    chatbot_id: chatbot.id,
    last_step_no: sample[:last_step_no],
    last_step_description: sample[:last_step_description],
    start_time: now - 2.minutes,
    end_time: sample[:end_time],
    result: sample[:result],
    path: sample[:path],
    payment: sample[:payment],
    lexica_order_id: sample[:lexica_order_id],
    sku: "SAMPLE-SKU",
    product_url: SHOP_URL,
    cart_url: CART_URL,
    error_kind: sample[:error_kind],
    error_message: sample[:error_message],
    screenshot_path: nil,
    masked_pan: sample[:masked_pan],
    card_expiry: sample[:card_expiry],
    card_holder: sample[:card_holder],
    token_key: nil
  )
  row.rpa_steps_array = sample[:rpa_steps]
  row.save!

  upsert_response.call(sample[:user_input_id], "user_email", sample[:email])
  upsert_response.call(sample[:user_input_id], "path", sample[:path])
  sample[:answers].each do |name, value|
    upsert_response.call(sample[:user_input_id], name, value)
  end
  upsert_response.call(sample[:user_input_id], "password", SAMPLE_PASSWORD) if sample[:with_password]

  status = ScenarioUserResponseStatus.find_or_initialize_by(
    scenario_id: scenario.id,
    user_input_id: sample[:user_input_id]
  )
  status.status = sample[:finished] ? :finished : :un_finished
  status.save!

  next unless sample[:cv]

  Order.find_or_create_by!(
    client_id: client.id,
    scenario_id: scenario.id,
    user_input_id: sample[:user_input_id],
    bot_type: :web
  )
end

puts "Lexica sample (未来) ready."
puts "  shop admin: mirai-admin@local.test / #{PASSWORD}"
puts "  shop user:  mirai@local.test / #{PASSWORD}"
puts "  bot: 未来 レキシカ"
puts "  v2: /v2/admin/bot-orders"
