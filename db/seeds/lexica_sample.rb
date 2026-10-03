# frozen_string_literal: true

# Development sample for 未来 (Mirai) Lexica. Idempotent. Does not change Local Dev.
# Does not enqueue LexicaScenarioJob.

require "base64"

load Rails.root.join("db/seeds/im_pinch_conversation.rb") unless defined?(Seeds::ImPinchConversation)

PASSWORD = "Password123!"
CART_URL = "https://cart.mirai-japan.co.jp/"
SHOP_URL = "https://mirai-japan.co.jp/"
LP_URL = "https://lp.mirai-japan.co.jp/ab/QvEvbJAyCPfzYIkKS_gvQ"
OPERATOR_ICON = "https://botchan.blob.core.windows.net/production/uploads/bot_picture/624c0e7303a30.png"
PINCH_IMG = {
  pay_promo: "https://botchan.blob.core.windows.net/production/uploads/673558c45bab41435c7a02fd/691d81ce2416a.jpg",
  pay_banner: "https://botchan.blob.core.windows.net/production/uploads/673558c45bab41435c7a02fd/691d81d7b0fd6.jpg",
  upsell_compare: "https://botchan.blob.core.windows.net/production/uploads/673558c45bab41435c7a02fd/698eda16091db.png",
  upsell_keep: "https://botchan.blob.core.windows.net/production/uploads/673558c45bab41435c7a02fd/6a700da702ba7.png",
  upsell_30ml: "https://botchan.blob.core.windows.net/production/uploads/673558c45bab41435c7a02fd/6a700da70af82.png",
  upsell_footer: "https://botchan.blob.core.windows.net/production/uploads/673558c45bab41435c7a02fd/698ecf21ce111.png",
  confirm_hero_1: "https://botchan.blob.core.windows.net/production/uploads/673558c45bab41435c7a02fd/689dad9ed20f6.jpg",
  confirm_hero_2: "https://botchan.blob.core.windows.net/production/uploads/673558c45bab41435c7a02fd/689dad9ebd5cf.jpg"
}.freeze
PINCH_CARD_BRAND_URLS = [
  ["VISA", "https://app2.blob.core.windows.net/botchan/images/card_type/visa.png"],
  ["JCB", "https://app2.blob.core.windows.net/botchan/images/card_type/jcb.png"],
  ["Mastercard", "https://app2.blob.core.windows.net/botchan/images/card_type/mastercard.png"],
  ["AMEX", "https://app2.blob.core.windows.net/botchan/images/card_type/amex.png"],
  ["Diners", "https://app2.blob.core.windows.net/botchan/images/card_type/diners.png"]
].freeze
PINCH_CARD_BRANDS_HTML = %(<div class="pinch-card-brands">#{PINCH_CARD_BRAND_URLS.map { |alt, src| %(<img src="#{src}" alt="#{alt}" />) }.join}</div>)
PINCH_CONFIRM_HTML = <<~HTML
  <div class="pinch-confirm">
    <a class="pinch-confirm-edit" href="#">修正したい場合はこちら</a>
    <div class="pinch-confirm-title">◆注文内容◆</div>
    <div class="pinch-confirm-row"><span>商品名</span><span>I'm PINCH10ml　7日間お試しキット（単品）</span></div>
    <div class="pinch-confirm-row"><span>数量</span><span>1点</span></div>
    <div class="pinch-confirm-row"><span>金額</span><span>980円（税込）</span></div>
    <div class="pinch-confirm-row"><span>手数料</span><span>0円</span></div>
    <div class="pinch-confirm-row"><span>送料</span><span>0円</span></div>
    <div class="pinch-confirm-row"><span>合計</span><span>980円（税込）</span></div>
    <div class="pinch-confirm-title">◆お客様情報（お届け先）◆</div>
    <div class="pinch-confirm-row"><span>お名前</span><span>テスト テスト</span></div>
    <div class="pinch-confirm-row"><span>住所</span><span>〒1000001 東京都千代田区千代田1-1</span></div>
    <div class="pinch-confirm-row"><span>電話番号</span><span>09012345678</span></div>
    <div class="pinch-confirm-row"><span>メールアドレス</span><span>pinch@test.test</span></div>
    <div class="pinch-confirm-title">◆配送方法◆</div>
    <div class="pinch-confirm-row"><span>配送方法</span><span>ポスト投函（ご在宅不要）</span></div>
    <div class="pinch-confirm-title">◆お支払い方法◆</div>
    <div class="pinch-confirm-row"><span>お支払い方法</span><span>後払い（コンビニ・郵便局）</span></div>
    <p>クレジットカード：商品発送時に決済(お届け日の1日～7日前)いたします。</p>
    <p>後払い：商品に同封する請求書にて商品到着から14日以内にお手続きください。</p>
    <p>お支払い期限を一定期間過ぎてもお支払いの確認がとれない場合、ご請求金額に回収事務手数料297円 (税込) が加算されます。(最大3回、合計 891円)</p>
    <div class="pinch-confirm-title">◆お届けについて◆</div>
    <p>お届けはご注文から3営業日程度でお届けします。</p>
    <div class="pinch-confirm-title">◆変更・返品について◆</div>
    <p>変更・解約をご希望の場合は、お届け日の7日前までご連絡を承っておりますので安心してお試しください。</p>
    <p>美容コンサルティング窓口：お電話番号　0120-577-361※平日9時～18時</p>
    <p>メールアドレス　info@impinch.com※24時間受付可能</p>
  </div>
HTML
PINCH_CONFIRM_PRIVACY = <<~TEXT
  お客様からお教えいただく個人情報は、厳重に取り扱ってまいります。お客様がご自身の個人情報に関する開示、登録内容の変更・訂正等を希望される場合には、合理的な範囲で速やかに対応いたします。お問合せや訂正などがございましたら上記お客様おもてなし窓口にご連絡くださいますようお願いいたします。
  お教えいただきましたお客様の情報に関しましては以下のように活かしていきます。
  ●お手紙や定期会報誌、キャンペーンのご案内等をお届けするため
  ●ご利用いただいている商品やサービスの提供・改良や新たなサービスを開発するため
  個人情報は以下のような特例を除き第三者に開示・提供することは決してありません。
  (1)ご本人様の同意がある場合
  (2)統計的データとして、お客様個人を識別できない状態に加工した場合
  (3)法令等により提供を求められた場合
TEXT
SAMPLE_PASSWORD = "Sample1234"
LAUNCH_BUTTON_SELECTORS = ".bot_open, .p-cta__bodyBtn_a, .p-ctasp__btn12, .float.bot_open, .cta"
# Look measured from the original LP chat: CSS, LP-side JS and images live in db/seeds/im_pinch/.
PINCH_ASSET_DIR = Rails.root.join("db/seeds/im_pinch")
CUSTOM_CSS = File.read(PINCH_ASSET_DIR.join("custom.css"), encoding: "UTF-8")
CUSTOM_LP_JS = File.read(PINCH_ASSET_DIR.join("lp.js"), encoding: "UTF-8")
PINCH_GENDER_TILES = %w[male female].to_h do |gender|
  image = File.binread(PINCH_ASSET_DIR.join("gender-#{gender}.png"))
  ["gender_#{gender}".to_sym, "data:image/png;base64,#{Base64.strict_encode64(image)}"]
end.freeze

PINCH_DESIGN_SETTINGS = {
  display_type: 3,
  width_pc: 500,
  height_pc: 680,
  width_sp: 100,
  height_sp: 100,
  position_pc: 1,
  button_type_pc: 2,
  right_position_pc_title: "",
  right_margin_pc: 5,
  bottom_margin_pc: 0,
  position_sp: 1,
  button_type_sp: 2,
  right_position_sp_title: "",
  right_margin_sp: 0,
  bottom_margin_sp: 0,
  popup_close_bot: true,
  title_bubble: "30秒でカンタンお申込み♪",
  open_animation_duration_ms: 400,
  open_animation_style: "slide_up",
  theme: {
    header_title_text_color: "#FFFFFF",
    header_title_font_size: "15px",
    header_subtitle_text_color: "#FFFFFF",
    header_subtitle_font_size: "13px",
    chat_window_bg_color: "#F7E9E5",
    bot_message_bg_color: "#FFEEEE",
    bot_message_text_color: "#333333",
    bot_message_font_size: "19px",
    bot_message_border_style: "no_tail",
    user_message_bg_color: "#F5F5F5",
    user_message_text_color: "#333333",
    user_message_font_size: "17px",
    user_message_border_style: "no_tail",
    required_label_text_color: "#FF0000",
    required_label_font_size: "12px",
    field_font_size: "17px",
    field_unfocus_bg_color: "#FFFFFF",
    field_unfocus_border_color: "#E0E0E0",
    field_focus_bg_color: "#FFFFFF",
    field_focus_border_color: "#0597F2",
    field_focus_bg_effect: "none",
    radio_unselected_bg_color: "#FFFFFF",
    radio_unselected_border_color: "#E0E0E0",
    radio_selected_bg_color: "#FFB1C2",
    radio_selected_border_color: "#EE4D67",
    radio_font_size: "17px",
    radio_selected_border_effect: "none",
    checkbox_unchecked_bg_color: "#FFFFFF",
    checkbox_unchecked_border_color: "#E0E0E0",
    checkbox_checked_bg_color: "#F6CA21",
    checkbox_checked_border_color: "#F6CA21",
    checkbox_font_size: "17px",
    checkbox_checked_border_effect: "none",
    button_normal_bg_color: "#02BB92",
    button_normal_text_color: "#FFFFFF",
    button_pressed_bg_color: "#019A78",
    button_pressed_text_color: "#FFFFFF",
    button_disabled_bg_color: "#D0D6DC",
    button_disabled_text_color: "#FFFFFF",
    button_font_size: "14px",
    button_border_style: "pill",
    button_effect: "none",
    button_width: "100%",
    button_position: "center",
    progress_bar_bg_color: "#FFFFFF",
    progress_bar_text_color: "#F19F95",
    progress_bar_font_size: "13px",
    modal_bg_color: "#FFFFFF",
    modal_title_text_color: "#333333",
    modal_title_font_size: "17px",
    modal_title_alignment: "left",
    modal_cancel_button_bg_color: "#FFFFFF",
    modal_cancel_button_text_color: "#333333",
    modal_cancel_button_border_color: "#E0E0E0",
    modal_close_button_bg_color: "#02BB92",
    modal_close_button_text_color: "#FFFFFF",
    modal_button_font_size: "16px",
    validation_message_bg_color: "#FFF0F0",
    validation_message_text_color: "#CC0000",
    validation_message_font_size: "13px",
    error_message_bg_color: "#FFF0F0",
    error_message_text_color: "#CC0000",
    error_message_font_size: "13px"
  }
}.freeze

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
staff = User.find_by!(email: "mirai@local.test")

chatbot = Chatbot.find_by(bot_name: "I'm PINCH") || Chatbot.find_or_initialize_by(bot_name: "未来 レキシカ")
chatbot.assign_attributes(
  user: owner,
  bot_name: "I'm PINCH",
  title: "30秒でカンタンお申込み♪",
  subtitle: "I'm PINCH美容液",
  design_type: :flat,
  main_color: :yellow,
  status: :on,
  chat_body_version: "2.0",
  design_settings: PINCH_DESIGN_SETTINGS.to_json
)
chatbot.icon = File.open(PINCH_ASSET_DIR.join("avatar.png")) if chatbot.icon.blank?
chatbot.opening_bot_icon = File.open(PINCH_ASSET_DIR.join("logo.jpg")) if chatbot.opening_bot_icon.blank?
chatbot.save!

%w[
  path
  user_email
  user_name
  user_name_kana
  zip_code_address
  phone_number
  birth_date
  password
  payment_method
  credit_card_payment
  upsell
].each do |name|
  Variable.find_or_create_by!(chatbot: chatbot, variable_name: name) do |variable|
    variable.default_value = ""
  end
end

[owner, staff].each do |member|
  UserChatbot.find_or_create_by!(user: member, chatbot: chatbot) do |join|
    join.role = member == owner ? :bot_admin : :editor
  end
end

conversation = Seeds::ImPinchConversation.build(
  PINCH_IMG.merge(PINCH_GENDER_TILES).merge(
    card_brands_html: PINCH_CARD_BRANDS_HTML,
    confirm_html: PINCH_CONFIRM_HTML,
    confirm_privacy: PINCH_CONFIRM_PRIVACY
  )
)

scenario = Scenario.find_by(chatbot: chatbot, name: "I'm PINCH お申し込み") ||
  Scenario.find_or_initialize_by(chatbot: chatbot, name: "未来 待ち")
scenario.assign_attributes(
  name: "I'm PINCH お申し込み",
  scenario_type: "payment",
  merchandise_id: "SAMPLE-SKU",
  landing_page_product_url: LP_URL,
  lexica_cart_url: CART_URL,
  order_result_mode: "async",
  lexica_upsell_product_url: SHOP_URL,
  lexica_upsell_sku: "SAMPLE-UPSELL-SKU",
  lexica_cross_sell_product_url: SHOP_URL,
  lexica_cross_sell_sku: "SAMPLE-XSELL-SKU",
  lexica_offer_chat: true,
  lexica_offer_confirm_upsell: true,
  lexica_offer_confirm_cross_sell: false,
  lexica_offer_thanks_upsell: true,
  lexica_offer_thanks_cross_sell: true,
  is_used_custom_css: true,
  custom_css_content: CUSTOM_CSS,
  is_used_custom_js_code: true,
  bottom_body_custom_js_code: CUSTOM_LP_JS,
  launch_button_selectors: LAUNCH_BUTTON_SELECTORS,
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
  ipcode: "20120070091",
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
    payment: "gmo_atobarai",
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
    product_url: LP_URL,
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

puts "Lexica sample (未来 / I'm PINCH) ready."
puts "  shop admin: mirai-admin@local.test / #{PASSWORD}"
puts "  shop user:  mirai@local.test / #{PASSWORD}"
puts "  bot: I'm PINCH"
puts "  scenario: I'm PINCH お申し込み (async)"
puts "  v2: /v2/admin/bot-orders"
