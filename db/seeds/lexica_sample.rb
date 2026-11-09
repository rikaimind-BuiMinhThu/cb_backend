# frozen_string_literal: true

# Development sample for 未来 (Mirai) Lexica. Idempotent. Does not change Local Dev.
# Does not enqueue LexicaScenarioJob.
#
# Staging parity (bot 325 / scenario 549, 2026-11-09) — Design → ボタン:
#   button_normal_bg_color   #01bb92  / text #ffffff
#   button_pressed_bg_color  #10997b  / text #ffffff
#   button_disabled_bg_color #09866b  / text #ffffff
# Scenario custom_css_content matches staging (~10.3k; payment radios + #msg_id_26/27 full-bleed).
# Submit (注文を確定する): no loading_config on staging; button_image_width 50%.

load Rails.root.join("db/seeds/im_pinch_conversation.rb") unless defined?(Seeds::ImPinchConversation)

PASSWORD = "Password123!"
CART_URL = "https://cart.mirai-japan.co.jp/"
# I'm PINCH 10ml 7日間お試しキット（単品）. LP AddItemToCart id. SAMPLE-SKU is not a cart item.
PINCH_TRIAL_SKU = "_P046"
PINCH_HEADER_LOGO_PATH = Rails.root.join("db/seeds/assets/pinch_header_logo.jpg")
PINCH_HEADER_LOGO_DATA_URI = if File.file?(PINCH_HEADER_LOGO_PATH)
  "data:image/jpeg;base64,#{Base64.strict_encode64(File.binread(PINCH_HEADER_LOGO_PATH))}"
else
  ""
end
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
  ["Mastercard", "https://app2.blob.core.windows.net/botchan/images/card_type/master_card.png"],
  ["AMEX", "https://app2.blob.core.windows.net/botchan/images/card_type/american_express.png"],
  ["Diners", "https://app2.blob.core.windows.net/botchan/images/card_type/diner_club.png"]
].freeze
PINCH_CARD_BRANDS_HTML = %(<div class="pinch-card-brands">#{PINCH_CARD_BRAND_URLS.map { |alt, src| %(<img src="#{src}" alt="#{alt}" />) }.join}</div>)
PINCH_CONFIRM_CSS = <<~CSS
  <style>
  .pinch-order-confirm{font-size:14px;line-height:1.55;color:#222;background:#fff}
  .pinch-order-confirm .return_infutsFields{text-align:right;margin:0 0 10px}
  .pinch-order-confirm .return_infutsFields a{color:#0597F2;text-decoration:underline;font-size:13px}
  .pinch-order-confirm .confirm_title{text-align:center;font-weight:700;font-size:15px;margin:18px 0 8px;color:#000}
  .pinch-order-confirm .item_area{display:flex;align-items:flex-start;justify-content:space-between;gap:10px;padding:10px 0}
  .pinch-order-confirm .confirm_item_title{flex:0 0 auto;max-width:42%}
  .pinch-order-confirm .confirm_item_name{display:inline-block;background:#ececec;padding:2px 8px;font-size:13px;line-height:1.4;color:#333}
  .pinch-order-confirm .confirm_item_variable{flex:1 1 auto;text-align:right;word-break:break-word;font-size:14px}
  .pinch-order-confirm .item_area--product .confirm_item_variable{text-align:left}
  .pinch-order-confirm .bold-red{color:#e53935;font-weight:700}
  .pinch-order-confirm hr{border:0;border-top:1px solid #222;margin:0;opacity:.55}
  .pinch-order-confirm .confirm_item_variable_title{display:block;font-weight:700;margin:12px 0 6px;font-size:14px}
  .pinch-order-confirm .confirm_body,.pinch-order-confirm .confirm_note_block{font-size:13px;line-height:1.65;margin:0 0 12px;white-space:pre-wrap;text-align:left}
  .pinch-order-confirm .note{display:block;margin-top:8px;font-size:12px}
  </style>
CSS
PINCH_CONFIRM_PAYMENT_NOTE = <<~HTML
    <div class="confirm_item_variable_title">お支払方法・お支払時期</div>
    <div class="confirm_note_block">クレジットカード：商品発送時に決済(お届け日の1日～7日前)。
  後払い：商品同封の請求書にて到着後14日以内にお支払い。
  <span class="note">支払い期限を一定期間過ぎても未払いの場合、回収事務手数料297円 (税込) が加算。
  (最大3回、 合計 891円) https://www.impinch.com/company/index_test.html</span></div>
HTML
PINCH_CONFIRM_HTML = <<~HTML
  #{PINCH_CONFIRM_CSS.strip}
  <div class="pinch-order-confirm">
    <div class="return_infutsFields"><a href="#chat_user_names">修正したい場合はこちら</a></div>
    <div class="confirm_title">◆お申込み商品◆</div>
    <div class="item_area item_area--product">
      <span class="confirm_item_title"><span class="confirm_item_name">商品名</span></span>
      <span class="confirm_item_variable">【特別価格】I'm　PINCH  21日分定期ケアコース（初回30mlサイズ）</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">数量</span></span>
      <span class="confirm_item_variable">1点</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">金額</span></span>
      <span class="confirm_item_variable bold-red">1,980円（税込）</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">手数料</span></span>
      <span class="confirm_item_variable">0円</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">送料</span></span>
      <span class="confirm_item_variable">0円</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">合計</span></span>
      <span class="confirm_item_variable bold-red">1,980円（税込）</span>
    </div>
    <hr>
    <div class="item_area item_area--product">
      <span class="confirm_item_title"><span class="confirm_item_name">配送方法</span></span>
      <span class="confirm_item_variable">ポスト投函（ご在宅不要）</span>
    </div>
    <div class="confirm_title">◆お客様情報（お届け先）◆</div>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">お名前</span></span>
      <span class="confirm_item_variable">{{user_name}}</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">住所</span></span>
      <span class="confirm_item_variable">{{zip_code_address}}</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">電話番号</span></span>
      <span class="confirm_item_variable">{{phone_number}}</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">メールアドレス</span></span>
      <span class="confirm_item_variable">{{user_email}}</span>
    </div>
    <div class="confirm_title">◆お支払い方法◆</div>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">お支払い方法</span></span>
      <span class="confirm_item_variable">{{payment_method}}</span>
    </div>
    #{PINCH_CONFIRM_PAYMENT_NOTE.strip}
    <hr>
    <div class="confirm_title">◆お届けについて◆</div>
    <div class="confirm_body">定期お届けコースは、中止のお申し出があるまで自動でお届けします。 ※購入回数の縛りはありません。
  初回（30mlサイズ）：ご注文から3営業日程度でお届け。ポスト投函。 ２回目（60mlサイズ）：初回発送の21日後に1本お届け。宅配便でお届け。
  3回目以降（60mlサイズ）：30日間隔で毎月1本（2回目お届け日と同じ日のお届け）のお届け。宅配便でお届け。
  2回目以降は1本（60ml）ずっと15％OFFの10,909円（税込）、送料無料。 仮に3回継続した場合の代金総額は23,798円（税込）。</div>
    <hr>
    <div class="confirm_title">◆変更・返品・解約について◆</div>
    <div class="confirm_body">次回お届け日の7日前までにご連絡ください。
  美容コンサルティング窓口：
  お電話番号　0120-577-361※平日9時～18時
  メールアドレス　info@impinch.com※24時間受付可能
  お電話1本、メール１本でお休み・変更・解約を承ります。</div>
  </div>
HTML
PINCH_CONFIRM_HTML_TRIAL = <<~HTML
  #{PINCH_CONFIRM_CSS.strip}
  <div class="pinch-order-confirm">
    <div class="return_infutsFields"><a href="#chat_user_names">修正したい場合はこちら</a></div>
    <div class="confirm_title">◆お申込み商品◆</div>
    <div class="item_area item_area--product">
      <span class="confirm_item_title"><span class="confirm_item_name">商品名</span></span>
      <span class="confirm_item_variable">I'm PINCH10ml　7日間お試しキット（単品）</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">数量</span></span>
      <span class="confirm_item_variable">1点</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">金額</span></span>
      <span class="confirm_item_variable bold-red">980円（税込）</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">手数料</span></span>
      <span class="confirm_item_variable">0円</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">送料</span></span>
      <span class="confirm_item_variable">0円</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">合計</span></span>
      <span class="confirm_item_variable bold-red">980円（税込）</span>
    </div>
    <hr>
    <div class="item_area item_area--product">
      <span class="confirm_item_title"><span class="confirm_item_name">配送方法</span></span>
      <span class="confirm_item_variable">ポスト投函（ご在宅不要）</span>
    </div>
    <div class="confirm_title">◆お客様情報（お届け先）◆</div>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">お名前</span></span>
      <span class="confirm_item_variable">{{user_name}}</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">住所</span></span>
      <span class="confirm_item_variable">{{zip_code_address}}</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">電話番号</span></span>
      <span class="confirm_item_variable">{{phone_number}}</span>
    </div>
    <hr>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">メールアドレス</span></span>
      <span class="confirm_item_variable">{{user_email}}</span>
    </div>
    <div class="confirm_title">◆お支払い方法◆</div>
    <div class="item_area">
      <span class="confirm_item_title"><span class="confirm_item_name">お支払い方法</span></span>
      <span class="confirm_item_variable">{{payment_method}}</span>
    </div>
    #{PINCH_CONFIRM_PAYMENT_NOTE.strip}
    <hr>
    <div class="confirm_title">◆お届けについて◆</div>
    <div class="confirm_body">ご注文から3営業日程度でお届けします。ポスト投函（ご在宅不要）。</div>
    <hr>
    <div class="confirm_title">◆変更・返品・解約について◆</div>
    <div class="confirm_body">商品到着後、お肌に合わない場合は返金制度をご利用いただけます。
  美容コンサルティング窓口：
  お電話番号　0120-577-361※平日9時～18時
  メールアドレス　info@impinch.com※24時間受付可能</div>
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
LAUNCH_BUTTON_SELECTORS = ".bot_open, .p-cta__bodyBtn_a, .p-ctasp__btn12, .float.bot_open"
CUSTOM_CSS = <<~CSS
#sp-body {
  background: radial-gradient(circle, rgba(255, 210, 209, 1) 0%, rgba(255, 249, 251, 1) 61%) !important;
}
#sp-body .ss-bot-chat-detail-content {
  padding: 15px 12px !important;
}
#sp-container1 #sp-body.sp-body .ss-user-message__content-wrapper > .m-b-10:has(+ .sp-user-message-button-action) {
  margin-bottom: 0 !important;
}
#sp-container1 #sp-body.sp-body .ss-user-message__content-wrapper > .sp-user-message-button-action {
  margin-top: 0 !important;
  padding-top: 48px !important;
}
#sp-container1 #sp-body.sp-body .sp-user-message-button-action button.ss-user-message__action-btn {
  min-height: 64px !important;
  height: 64px !important;
  line-height: 1 !important;
  box-sizing: border-box !important;
  padding: 0 16px !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
}
#sp-container1 #sp-body.sp-body .ss-user-message__content-wrapper:has(.ss-email-domain-suggestions) > .m-b-10:has(.ss-email-domain-suggestions) > .ss-message__content--user-text-input-top > .ss-message__content--user-text-input-title::before,
#sp-container1 #sp-body.sp-body .ss-user-message__content-wrapper:has(.ss-email-domain-suggestions) > .m-b-10:has(input[inputmode="numeric"]) > .ss-message__content--user-text-input-top > .ss-message__content--user-text-input-title::before {
  content: "";
  display: inline-block;
  width: 24px;
  height: 24px;
  margin-right: 6px;
  vertical-align: -5px;
  background-repeat: no-repeat;
  background-position: center;
  background-size: contain;
}

#sp-container1 #sp-body.sp-body .ss-user-message__content-wrapper:has(.ss-email-domain-suggestions) > .m-b-10:has(.ss-email-domain-suggestions) > .ss-message__content--user-text-input-top > .ss-message__content--user-text-input-title::before {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24'%3E%3Cpath stroke='%23333333' stroke-width='1.6' stroke-linecap='round' stroke-linejoin='round' d='M4 6h16a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1z'/%3E%3Cpath stroke='%23333333' stroke-width='1.6' stroke-linecap='round' stroke-linejoin='round' d='m3 7 9 6 9-6'/%3E%3C/svg%3E");
}

#sp-container1 #sp-body.sp-body .ss-user-message__content-wrapper:has(.ss-email-domain-suggestions) > .m-b-10:has(input[inputmode="numeric"]) > .ss-message__content--user-text-input-top > .ss-message__content--user-text-input-title::before {
  width: 18px;
  height: 18px;
  vertical-align: -3px;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 512 512'%3E%3Cpath fill='%23000' d='M164.9 24.6c-7.7-18.6-28-28.5-47.4-23.2l-88 24C12.1 30.2 0 46 0 64C0 311.4 200.6 512 448 512c18 0 33.8-12.1 38.6-29.5l24-88c5.3-19.4-4.6-39.7-23.2-47.4l-96-40c-16.3-6.8-35.2-2.1-46.3 11.6L304.7 368C234.3 334.7 177.3 277.7 144 207.3L193.3 167c13.7-11.2 18.4-30 11.6-46.3l-40-96z'/%3E%3C/svg%3E");
}
.ss-user-message__content-wrapper:has([data-messsagetype="zip_code_address"]) .ss-message__content--user-pull_down-title {
  display: none !important;
}

.ss-message__content--user-zip-code-address-search-link,
.ss-message__content--user-zip-code-address-search-link span {
  font-size: 12px !important;
  line-height: 1.2 !important;
}
.ss-message__content--user-pull_down-top:has(+ .ss-message__content--user-pull_down--time_hm) .ss-message__content--user-pull_down-title {
  display: none !important;
}

@keyframes miraiPaymentBorderTwinkle {
  0%, 100% {
    border-color: #E02020;
    box-shadow: 0 0 0 2px #E02020;
  }
  50% {
    border-color: transparent;
    box-shadow: 0 0 0 2px transparent;
  }
}

/* MIRAI payment method side-by-side buttons */
/* Scope to default radios only — gender uses .options-gender_wrapper inside the same wrapper class. */
#sp-container1 #sp-body.sp-body .ss-message__content--user-radio_button-wrapper:has(> .ss-message__content--user-radio_button) {
  display: flex !important;
  flex-direction: row !important;
  gap: 8px !important;
  align-items: stretch !important;
}
#sp-container1 #sp-body.sp-body .ss-message__content--user-radio_button-wrapper:has(> .ss-message__content--user-radio_button) > .ss-message__content--user-radio_button {
  flex: 1 1 0 !important;
  margin-bottom: 0 !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  text-align: center !important;
  min-height: 56px !important;
  padding: 10px 8px !important;
  box-sizing: border-box !important;
  border-radius: 6px !important;
}
#sp-container1 #sp-body.sp-body .ss-message__content--user-radio_button-wrapper:has(> .ss-message__content--user-radio_button) > .ss-message__content--user-radio_button input[type="radio"] {
  position: absolute !important;
  opacity: 0 !important;
  width: 0 !important;
  height: 0 !important;
  pointer-events: none !important;
}
#sp-container1 #sp-body.sp-body .ss-message__content--user-radio_button-wrapper:has(> .ss-message__content--user-radio_button) > .ss-message__content--user-radio_button > label {
  margin: 0 !important;
  width: 100% !important;
  text-align: center !important;
  line-height: 1.3 !important;
  cursor: pointer !important;
  white-space: normal !important;
}
#sp-container1 #sp-body.sp-body .ss-message__content--user-radio_button-wrapper:has(> .ss-message__content--user-radio_button) > .ss-message__content--user-radio_button {
  background: #E6E6E6 !important;
  background-color: #E6E6E6 !important;
  border: 2px solid #E6E6E6 !important;
  animation: none !important;
}
#sp-container1 #sp-body.sp-body .ss-message__content--user-radio_button-wrapper:has(> .ss-message__content--user-radio_button) > .ss-message__content--user-radio_button > label {
  color: #9A9A9A !important;
}
#sp-container1 #sp-body.sp-body .ss-message__content--user-radio_button-wrapper:has(> .ss-message__content--user-radio_button) > .ss-message__content--user-radio_button--selected,
#sp-container1 #sp-body.sp-body .ss-message__content--user-radio_button-wrapper:has(> .ss-message__content--user-radio_button) > .ss-message__content--user-radio_button:has(input[type="radio"]:checked) {
  background: #7A4030 !important;
  background-color: #7A4030 !important;
  border: 2px solid #E02020 !important;
  outline: none !important;
  animation: miraiPaymentBorderTwinkle 1.2s ease-in-out infinite !important;
}
#sp-container1 #sp-body.sp-body .ss-message__content--user-radio_button-wrapper:has(> .ss-message__content--user-radio_button) > .ss-message__content--user-radio_button--selected > label,
#sp-container1 #sp-body.sp-body .ss-message__content--user-radio_button-wrapper:has(> .ss-message__content--user-radio_button) > .ss-message__content--user-radio_button:has(input[type="radio"]:checked) > label {
  color: #FFFFFF !important;
}

/* MIRAI msg_id_26 + msg_id_27 pinch combine full width */
/* Bleed past #sp-body 10px padding so promo/upsell match chatbot frame width. */
#sp-container1 #sp-body.sp-body #msg_id_26.sp-body-user-side,
#sp-container1 #sp-body.sp-body #msg_id_27.sp-body-user-side {
  width: calc(100% + 20px) !important;
  max-width: none !important;
  box-sizing: border-box !important;
  margin-left: -10px !important;
  margin-right: -10px !important;
  justify-content: stretch !important;
}
#sp-container1 #sp-body.sp-body #msg_id_26 .sp-body-user-side-messages,
#sp-container1 #sp-body.sp-body #msg_id_27 .sp-body-user-side-messages {
  width: 100% !important;
  max-width: 100% !important;
  box-sizing: border-box !important;
  padding: 0 !important;
  background: transparent !important;
  border-radius: 0 !important;
}
#sp-container1 #sp-body.sp-body #msg_id_26 .ss-user-message__content-wrapper,
#sp-container1 #sp-body.sp-body #msg_id_26 .ss-combine-message__content,
#sp-container1 #sp-body.sp-body #msg_id_26 .ss-combine-message__block,
#sp-container1 #sp-body.sp-body #msg_id_26 .ss-combine-message__block-inner,
#sp-container1 #sp-body.sp-body #msg_id_26 .ss-bot-chat-text-input-shell,
#sp-container1 #sp-body.sp-body #msg_id_27 .ss-user-message__content-wrapper,
#sp-container1 #sp-body.sp-body #msg_id_27 .ss-combine-message__content,
#sp-container1 #sp-body.sp-body #msg_id_27 .ss-combine-message__block,
#sp-container1 #sp-body.sp-body #msg_id_27 .ss-combine-message__block-inner,
#sp-container1 #sp-body.sp-body #msg_id_27 .ss-bot-chat-text-input-shell {
  width: 100% !important;
  max-width: 100% !important;
  box-sizing: border-box !important;
}
#sp-container1 #sp-body.sp-body #msg_id_26 .ss-combine-message__block,
#sp-container1 #sp-body.sp-body #msg_id_27 .ss-combine-message__block {
  padding: 0 !important;
  --ss-combine-block-padding: 0px !important;
}
#sp-container1 #sp-body.sp-body #msg_id_26 .ss-bot-chat-detail-content,
#sp-container1 #sp-body.sp-body #msg_id_26 .html-code-message-preview,
#sp-container1 #sp-body.sp-body #msg_id_27 .ss-bot-chat-detail-content,
#sp-container1 #sp-body.sp-body #msg_id_27 .html-code-message-preview {
  width: 100% !important;
  max-width: 100% !important;
  box-sizing: border-box !important;
  padding: 0 !important;
  background: transparent !important;
  border-radius: 0 !important;
}
#sp-container1 #sp-body.sp-body #msg_id_26 .pinch-bot-art,
#sp-container1 #sp-body.sp-body #msg_id_27 .pinch-bot-art {
  width: 100% !important;
  max-width: 100% !important;
  height: auto !important;
  display: block !important;
  object-fit: contain !important;
}
#sp-container1 #sp-body.sp-body #msg_id_26 .ss-user-chat-text-input-user-icon,
#sp-container1 #sp-body.sp-body #msg_id_27 .ss-user-chat-text-input-user-icon {
  display: none !important;
}
#sp-container1 .sp-body .ss-message__content--user-radio_button--radio_button_img.ss-message__content--user-radio_button--selected,
#sp-container .sp-body .ss-message__content--user-radio_button--radio_button_img.ss-message__content--user-radio_button--selected,
#sp-container1 .sp-body .ss-message__content--user-radio_button--radio_button_img:has(input[type="radio"]:checked),
#sp-container .sp-body .ss-message__content--user-radio_button--radio_button_img:has(input[type="radio"]:checked) {
  background: transparent !important;
  background-color: transparent !important;
  border: 1px solid #000 !important;
  animation: none !important;
}
CSS

PINCH_DESIGN_SETTINGS = {
  display_type: 2,
  width_pc: 500,
  height_pc: 680,
  width_sp: 100,
  height_sp: 100,
  position_pc: 1,
  button_type_pc: 2,
  right_position_pc_title: "30秒でカンタンお申込み♪",
  right_margin_pc: 10,
  bottom_margin_pc: 0,
  position_sp: 1,
  button_type_sp: 2,
  right_position_sp_title: "30秒でカンタンお申込み♪",
  right_margin_sp: 0,
  bottom_margin_sp: 0,
  popup_close_bot: true,
  title_bubble: "30秒でカンタンお申込み♪",
  open_animation_duration_ms: 400,
  open_animation_style: "slide_up",
  theme: {
    header_title_text_color: "#000000",
    header_title_font_size: "15px",
    header_title_bold: true,
    header_subtitle_visible: false,
    header_subtitle_text_color: "#FFFFFF",
    header_subtitle_font_size: "13px",
    header_subtitle_bold: false,
    header_chrome: "title_only",
    header_title_alignment: "center",
    header_close_icon: "times",
    header_close_icon_color: "#9e9e9e",
    header_bg_color: "#FFFFFF",
    header_logo_image: PINCH_HEADER_LOGO_DATA_URI,
    header_height: "34px",
    progress_bar_container_bg_color: "#f7e9e5",
    progress_bar_bg_color: "#ffffff",
    progress_bar_text_color: "#F48879",
    progress_bar_font_size: "12px",
    progress_bar_bold: true,
    progress_bar_height: "10px",
    progress_bar_radius: "20px",
    progress_bar_fill_color: "#F19F95",
    progress_bar_style: "style2",
    progress_label_mode: "fraction",
    progress_bar_above_text: "お申し込み最短30秒",
    chat_window_bg_color: "#F7E9E5",
    bot_message_bg_color: "#FFEEEE",
    bot_message_text_color: "#333333",
    bot_message_font_size: "17px",
    bot_message_bold: false,
    bot_message_border_style: "no_tail",
    user_message_bg_color: "#F5F5F5",
    user_message_text_color: "#333333",
    user_message_font_size: "17px",
    user_message_bold: false,
    user_message_border_style: "with_tail",
    field_focus_border_color: "#0597F2",
    field_focus_border_width: "2px",
    field_focus_bg_color: "#FFFFFF",
    field_focus_bg_effect: "outline_soft",
    field_unfocus_border_color: "#E0E0E0",
    field_unfocus_border_width: "1px",
    field_unfocus_bg_color: "#F7E9E5",
    field_font_size: "17px",
    field_text_bold: false,
    field_placeholder_bold: false,
    field_placeholder_style: "float",
    field_placeholder_font_size: "16px",
    field_placeholder_focus_font_size: "10px",
    field_title_bold: true,
    field_title_font_size: "17px",
    field_title_letter_spacing: "2px",
    validation_message_bg_color: "#FFF0F0",
    validation_message_text_color: "#CC0000",
    validation_message_font_size: "13px",
    required_label_text_color: "#FF0000",
    required_label_font_size: "12px",
    button_normal_bg_color: "#01bb92",
    button_normal_text_color: "#ffffff",
    button_pressed_bg_color: "#10997b",
    button_pressed_text_color: "#ffffff",
    button_disabled_bg_color: "#09866b",
    button_disabled_text_color: "#ffffff",
    button_font_size: "16px",
    button_bold: false,
    button_border_style: "pill",
    button_effect: "shake",
    button_width: "100%",
    button_padding: "1px 8px",
    button_position: "center",
    checkbox_unchecked_bg_color: "#FFFFFF",
    checkbox_unchecked_border_color: "#E0E0E0",
    checkbox_checked_bg_color: "#F6CA21",
    checkbox_checked_border_color: "#F6CA21",
    checkbox_checked_border_effect: "none",
    checkbox_font_size: "17px",
    radio_unselected_bg_color: "#FFFFFF",
    radio_selected_bg_color: "#8C6049",
    radio_unselected_border_color: "#E0E0E0",
    radio_selected_border_color: "#8C6049",
    radio_selected_border_effect: "none",
    radio_input_unselected_color: "#cccccc",
    radio_input_selected_color: "yellow",
    radio_font_size: "17px",
    error_message_bg_color: "#FFF0F0",
    error_message_text_color: "#CC0000",
    error_message_font_size: "13px",
    thanks_message_bg_color: "#e8f5e9",
    thanks_message_text_color: "#2e7d32",
    thanks_message_font_size: "14px",
    modal_bg_color: "#FFFFFF",
    modal_title_text_color: "#333333",
    modal_title_font_size: "17px",
    modal_title_alignment: "left",
    modal_cancel_button_bg_color: "#D9534F",
    modal_cancel_button_text_color: "#FFFFFF",
    modal_cancel_button_border_color: "#AC2925",
    modal_close_button_bg_color: "#DDDDDD",
    modal_close_button_text_color: "#646464",
    modal_button_font_size: "14px"
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
  title: "I'm PINCH",
  subtitle: "x",
  design_type: :material,
  main_color: :yellow,
  status: :on,
  chat_body_version: "2.0",
  design_settings: PINCH_DESIGN_SETTINGS.to_json
)
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
  PINCH_IMG.merge(
    card_brands_html: PINCH_CARD_BRANDS_HTML,
    confirm_html: PINCH_CONFIRM_HTML,
    confirm_html_trial: PINCH_CONFIRM_HTML_TRIAL,
    confirm_privacy: PINCH_CONFIRM_PRIVACY
  )
)

scenario = Scenario.find_by(chatbot: chatbot, name: "I'm PINCH お申し込み") ||
  Scenario.find_or_initialize_by(chatbot: chatbot, name: "未来 待ち")
scenario.assign_attributes(
  name: "I'm PINCH お申し込み",
  scenario_type: "payment",
  merchandise_id: PINCH_TRIAL_SKU,
  landing_page_product_url: LP_URL,
  lexica_cart_url: CART_URL,
  order_result_mode: "async",
  lexica_upsell_product_url: SHOP_URL,
  lexica_upsell_sku: "",
  lexica_cross_sell_product_url: SHOP_URL,
  lexica_cross_sell_sku: "",
  lexica_offer_chat: true,
  lexica_offer_confirm_upsell: true,
  lexica_offer_confirm_cross_sell: false,
  lexica_offer_thanks_upsell: false,
  lexica_offer_thanks_cross_sell: false,
  is_used_custom_css: true,
  custom_css_content: CUSTOM_CSS,
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
  },
  {
    user_input_id: "mirai-sample-recaptcha",
    result: :error,
    path: "first_time",
    payment: "gmo_atobarai",
    last_step_description: "reCAPTCHA v3 試行 5/5",
    last_step_no: 8,
    email: "recaptcha@test.test",
    end_time: now,
    lexica_order_id: nil,
    error_kind: "recaptcha",
    error_message: "リキャプチャの検証に失敗しました",
    masked_pan: nil,
    card_expiry: nil,
    card_holder: nil,
    rpa_steps: [
      { "name" => "fill_delivery", "description" => "お届け", "ok" => true, "url" => "#{CART_URL}order/signin" },
      {
        "name" => "recaptcha_v3_detect",
        "description" => "reCAPTCHA v3 検出",
        "ok" => true,
        "url" => "#{CART_URL}order/signin",
        "actions" => [
          { "type" => "detect", "where" => "api.js?render=", "label" => "sitekey", "value" => "6LfZil0U…g5fE" }
        ]
      },
      {
        "name" => "recaptcha_v3",
        "description" => "reCAPTCHA v3 試行 1/5",
        "ok" => false,
        "url" => "#{CART_URL}order/signin",
        "error" => "リキャプチャの検証に失敗しました",
        "actions" => [
          { "type" => "2captcha", "where" => "in.php", "label" => "task_id", "value" => "2122988149" },
          { "type" => "2captcha", "where" => "res.php", "label" => "reportbad", "value" => "2122988149" }
        ]
      },
      {
        "name" => "recaptcha_v3",
        "description" => "reCAPTCHA v3 試行 5/5",
        "ok" => false,
        "url" => "#{CART_URL}order/signin",
        "error" => "reCAPTCHA (2Captcha 5回失敗)",
        "actions" => [
          { "type" => "2captcha", "where" => "in.php", "label" => "task_id", "value" => "2122988150" },
          { "type" => "2captcha", "where" => "res.php", "label" => "reportbad", "value" => "2122988150" }
        ]
      }
    ],
    answers: PROFILE_ANSWERS,
    with_password: false,
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
