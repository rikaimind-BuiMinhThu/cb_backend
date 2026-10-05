# frozen_string_literal: true

owner = User.find_by!(email: "client-admin@local.test")
chatbot = Chatbot.find_by!(user: owner, bot_name: "Local Demo Bot")

bot_text = lambda do |id, content|
  {
    id: id,
    hidden: false,
    belong_to: "bot",
    conditions: [],
    message_content: [
      {
        type: "text_input",
        text_input: {
          content: content,
          use_for_confirm_message: false
        },
        getting_error_notification: {
          use_for_confirm_message: false
        },
        email: {},
        file: {},
        script: {},
        html_code: {},
        delay: {
          typing_on: false
        },
        api_link_age: {},
        clear_variable: {
          variables: []
        },
        variable_set: {
          variables: []
        }
      }
    ]
  }
end

user_text_input = lambda do |id, attrs|
  type = attrs.fetch(:type, "text")
  nested = {
    title_require: true,
    title: attrs.fetch(:title),
    require: true,
    isUseConvertText: false,
    isCustomID: false,
    convertTextTypeValue: "katakana",
    idRefector: "",
    is_save_input_content: true,
    save_input_content: attrs.fetch(:save_input_content),
    type: type,
    text: {
      range: "no_input",
      isSplitInput: false,
      placeholderLeft: attrs.fetch(:placeholder, attrs.fetch(:title))
    },
    urls: {},
    email_address: {
      placeholder: attrs.fetch(:placeholder, "email@example.com")
    },
    email_confirmation: {},
    phone_number: {
      withHyphen: false,
      disable_remove_leading_zero: false,
      number: attrs.fetch(:placeholder, "09012345678")
    },
    password: {
      password: attrs.fetch(:placeholder, "パスワード")
    },
    password_confirmation: {
      password: attrs.fetch(:placeholder, "パスワード"),
      confirm_password: "確認用パスワード"
    }
  }

  {
    id: id,
    hidden: false,
    belong_to: "user",
    conditions: [],
    is_display_button_next: true,
    message_content: [
      {
        id: 1,
        type: "text_input",
        text_input: nested
      }
    ]
  }
end

payment_conversation = {
  name: "Local Payment Scenario",
  messages: [
    bot_text.call(1, "ようこそ。ご注文手続きを開始します。"),
    user_text_input.call(2, title: "お名前", save_input_content: "user_name", placeholder: "お名前"),
    bot_text.call(3, "フリガナを入力してください。"),
    user_text_input.call(4, title: "フリガナ", save_input_content: "user_name_kana", placeholder: "フリガナ"),
    bot_text.call(5, "メールアドレスを入力してください。"),
    user_text_input.call(
      6,
      title: "メールアドレス",
      save_input_content: "user_email",
      type: "email_address",
      placeholder: "email@example.com"
    ),
    bot_text.call(7, "パスワードを設定してください。"),
    user_text_input.call(
      8,
      title: "パスワード",
      save_input_content: "password",
      type: "password",
      placeholder: "パスワード"
    ),
    bot_text.call(9, "ご住所を入力してください。"),
    {
      id: 10,
      hidden: false,
      belong_to: "user",
      conditions: [],
      is_display_button_next: true,
      message_content: [
        {
          id: 1,
          type: "zip_code_address",
          zip_code_address: {
            title_require: true,
            title: "ご住所",
            isCheckRequire: "require",
            post_code: "",
            is_use_dropdown: false,
            prefecture: nil,
            municipality: "",
            address: "",
            building_name: "",
            split_postal_code: false,
            compact_municipality_and_address: false,
            compact_municipality_and_address_and_building_name: false,
            post_code_label: "郵便番号",
            prefecture_label: "都道府県",
            municipality_label: "市区町村",
            address_label: "番地",
            building_name_label: "建物名"
          }
        }
      ]
    },
    bot_text.call(11, "電話番号を入力してください。"),
    user_text_input.call(
      12,
      title: "電話番号",
      save_input_content: "phone_number",
      type: "phone_number",
      placeholder: "09012345678"
    ),
    bot_text.call(13, "数量を選択してください。"),
    user_text_input.call(14, title: "数量", save_input_content: "quantity", placeholder: "1"),
    bot_text.call(15, "お支払い方法を選択してください。"),
    {
      id: 16,
      hidden: false,
      belong_to: "user",
      conditions: [],
      is_display_button_next: true,
      message_content: [
        {
          id: 1,
          type: "radio_button",
          radio_button: {
            title_require: true,
            title: "お支払い方法",
            require: true,
            type: "default",
            initial_selection: 1,
            is_save_input_content: true,
            save_input_content: "payment_method",
            img_layout: {
              type: "horizontal_equal_2",
              custom_widths: ["50", "50"]
            },
            option_padding: "0px",
            option_margin: "5px",
            default: [
              { id: 1, text: "クレジットカード", value: "credit_card" },
              { id: 2, text: "NP後払い", value: "np_deferred" }
            ],
            radio_button_img: [{ id: 1 }],
            upsell_button: [
              { id: 1, value: "アップセルする", img: "" },
              { id: 2, value: "そのまま注文する", img: "" }
            ],
            block_style: [{ id: 1 }]
          }
        }
      ]
    },
    bot_text.call(17, "カード情報を入力してください。"),
    {
      id: 18,
      hidden: false,
      belong_to: "user",
      conditions: [],
      is_display_button_next: true,
      message_content: [
        {
          id: 1,
          type: "card_payment_radio_button",
          card_payment_radio_button: {
            is_save_input_content: true,
            save_input_content: "credit_card_payment",
            require: true,
            type: "default",
            title_require: true,
            title: "クレジットカード",
            is_hide_card_name: false,
            is_hide_cvc: false,
            is_use_installment: [],
            separate_type: false,
            separate_name: false,
            validity_check: false,
            type_date_of_expiry: "ym",
            payment_method: [],
            card_linked_setting: [],
            initial_selection: 1,
            radio_contents: [
              { id: 1, text: "クレジットカード", value: "credit_card" }
            ],
            radio_contents_img: [
              {
                id: 1,
                contents: [{ id: 1 }]
              }
            ]
          }
        }
      ]
    },
    bot_text.call(19, "利用規約に同意してください。"),
    {
      id: 20,
      hidden: false,
      belong_to: "user",
      conditions: [],
      is_display_button_next: true,
      message_content: [
        {
          id: 1,
          type: "agree_term",
          agree_term: {
            require: true,
            title_require: true,
            title: "利用規約",
            term: "本サービス利用規約に同意します。",
            type: "detail_content",
            detail_content: {
              content: "シード用の利用規約です。"
            },
            post_link_only: [{}]
          }
        }
      ]
    }
  ]
}.to_json

payment_scenario = Scenario.find_or_initialize_by(chatbot: chatbot, name: "Local Payment Scenario")
payment_scenario.assign_attributes(
  scenario_type: "payment",
  conversation: payment_conversation,
  landing_page_product_url: "https://example.com/products/demo",
  execution_policy: :rpa,
  is_use_only_regular_order: false
)
payment_scenario.save!

tamago_config = TamagoRepeatConfig.find_or_initialize_by(scenario: payment_scenario)
tamago_config.assign_attributes(
  tamago_landing_page_url: "https://example.com/products/demo",
  add_to_cart_button_selector: "input#hide_display",
  is_regular_product: false,
  email_confirm_field: :email_confirm_optional,
  name_kana_field: :name_kana_optional
)
tamago_config.save!

faq_conversation = {
  name: "Local FAQ Scenario",
  messages: [
    bot_text.call(1, "よくある質問です。ご不明点を入力してください。"),
    user_text_input.call(
      2,
      title: "ご質問内容",
      save_input_content: "faq_question",
      placeholder: "ご質問内容"
    ),
    bot_text.call(3, "お問い合わせありがとうございます。担当よりご連絡します。")
  ]
}.to_json

faq_scenario = Scenario.find_or_initialize_by(chatbot: chatbot, name: "Local FAQ Scenario")
faq_scenario.assign_attributes(
  scenario_type: "faq",
  conversation: faq_conversation
)
faq_scenario.save!

chatbot.update!(scenario_selected: payment_scenario.id)

ScenarioPage.find_or_create_by!(scenario: payment_scenario, url: "https://example.com/lp/payment") do |page|
  page.num_type = :num_of_start
end

ScenarioPage.find_or_create_by!(scenario: payment_scenario, url: "https://example.com/lp/thanks") do |page|
  page.num_type = :num_of_cv
end

ScenarioPage.find_or_create_by!(scenario: faq_scenario, url: "https://example.com/faq") do |page|
  page.num_type = :num_of_start
end
