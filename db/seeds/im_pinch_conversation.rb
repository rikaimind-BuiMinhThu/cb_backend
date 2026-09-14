# frozen_string_literal: true

# I'm PINCH payment conversation (A / B / C). Loaded by lexica_sample.rb.

module Seeds
  module ImPinchConversation
    module_function

    def next_id
      @next_id += 1
    end

    def reset_ids!
      @next_id = 0
    end

    def cond_or(name, values)
      values.each_with_index.map do |value, index|
        item = { nameCondition: name, condition: "is", inputCondition: value }
        item[:linkCondition] = "or" if index.positive?
        item
      end
    end

    def cond_is(name, value)
      [{ nameCondition: name, condition: "is", inputCondition: value }]
    end

    def empty_content_fields
      {
        getting_error_notification: { use_for_confirm_message: false },
        email: {},
        file: {},
        script: {},
        html_code: {},
        delay: { typing_on: false },
        api_link_age: {},
        clear_variable: { variables: [] },
        variable_set: { variables: [] }
      }
    end

    def bot_text(content, conditions: [])
      {
        id: next_id,
        hidden: false,
        belong_to: "bot",
        conditions: conditions,
        message_content: [
          {
            type: "text_input",
            text_input: { content: content, use_for_confirm_message: false }
          }.merge(empty_content_fields)
        ]
      }
    end

    def bot_html(html, conditions: [])
      {
        id: next_id,
        hidden: false,
        belong_to: "bot",
        conditions: conditions,
        message_content: [
          {
            type: "html_code",
            text_input: {},
            html_code: { content: html, use_for_ugc: false },
            getting_error_notification: { use_for_confirm_message: false },
            email: {},
            file: {},
            script: {},
            delay: { typing_on: false },
            api_link_age: {},
            clear_variable: { variables: [] },
            variable_set: { variables: [] }
          }
        ]
      }
    end

    def bot_art(url, alt, conditions: [])
      bot_html(%(<img class="pinch-bot-art" src="#{url}" alt="#{alt}" />), conditions: conditions)
    end

    def user_message(*contents, conditions: [], next_button: true)
      {
        id: next_id,
        hidden: false,
        belong_to: "user",
        conditions: conditions,
        is_display_button_next: next_button,
        not_use_button: !next_button,
        message_content: contents.flatten
      }
    end

    def user_image(url, alt:, width: "100%")
      {
        id: 1,
        type: "image",
        image: {
          imageURL: url,
          image_width: width,
          image_height: "auto",
          alt: alt
        }
      }
    end

    def text_input(title, save_name, type, placeholder:, split: false, left: nil, right: nil, convert: false)
      {
        id: 1,
        type: "text_input",
        text_input: {
          title_require: true,
          title: title,
          require: true,
          isUseConvertText: convert,
          isCustomID: false,
          convertTextTypeValue: "katakana",
          idRefector: "",
          is_save_input_content: true,
          save_input_content: save_name,
          type: type,
          text: {
            range: "no_input",
            isSplitInput: split,
            placeholderLeft: left || placeholder,
            placeholderRight: right
          },
          urls: {},
          email_address: { placeholder: placeholder },
          email_confirmation: {},
          phone_number: {
            withHyphen: false,
            disable_remove_leading_zero: false,
            number: placeholder
          },
          password: { password: placeholder },
          password_confirmation: {}
        }
      }
    end

    def radio(title, save_name, options)
      {
        id: 1,
        type: "radio_button",
        radio_button: {
          title_require: true,
          title: title,
          require: true,
          type: "default",
          initial_selection: "",
          is_save_input_content: true,
          save_input_content: save_name,
          img_layout: { type: "horizontal_equal_2", custom_widths: ["50", "50"] },
          option_padding: "0px",
          option_margin: "5px",
          default: options.each_with_index.map { |option, index| option.merge(id: index + 1) },
          radio_button_img: [{ id: 1 }],
          upsell_button: [],
          block_style: [{ id: 1 }]
        }
      }
    end

    def gender_icon_data_uri(svg)
      "data:image/svg+xml,#{ERB::Util.url_encode(svg)}"
    end

    GENDER_ICON_MALE = Seeds::ImPinchConversation.gender_icon_data_uri(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><circle cx="12" cy="5" r="3.2" fill="#000"/><path fill="#000" d="M7.5 10.2c0-1 .8-1.8 1.8-1.8h5.4c1 0 1.8.8 1.8 1.8V16h-2.2v6.5h-4.6V16H7.5z"/></svg>'
    ).freeze
    GENDER_ICON_FEMALE = Seeds::ImPinchConversation.gender_icon_data_uri(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><circle cx="12" cy="5" r="3.2" fill="#000"/><path fill="#000" d="M12 8.6c-2 0-3.7.9-4.7 2.2L4.2 17.5h4.1V22h7.4v-4.5h4.1l-3.1-6.7C15.7 9.5 14 8.6 12 8.6z"/></svg>'
    ).freeze

    def gender_preset(button_default, button_hover, button_selected, icon_url:)
      {
        preset: {
          button: {
            default: button_default,
            hover: button_hover,
            selected: button_selected
          },
          icon: {
            url: icon_url,
            height: 32,
            width: 32,
            default: "#FFFFFF",
            hover: "#FFFFFF",
            selected: "#FFFFFF"
          }
        }
      }
    end

    def gender_radio(title, save_name)
      {
        id: 1,
        type: "radio_button",
        radio_button: {
          title_require: true,
          title: title,
          require: true,
          type: "default",
          initial_selection: "",
          is_save_input_content: true,
          save_input_content: save_name,
          use_as_gender: true,
          gender_display_type: "horizontal",
          img_layout: { type: "horizontal_equal_2", custom_widths: ["50", "50"] },
          option_padding: "0px",
          option_margin: "5px",
          default: [
            {
              id: 1,
              text: "男性",
              value: "male",
              preset_config: gender_preset("#7EB6E8", "#5A9BD4", "#3D7ABF", icon_url: GENDER_ICON_MALE)
            },
            {
              id: 2,
              text: "女性",
              value: "female",
              preset_config: gender_preset("#F5A3B5", "#EE8FA6", "#E56B88", icon_url: GENDER_ICON_FEMALE)
            }
          ],
          radio_button_img: [{ id: 1 }],
          upsell_button: [],
          block_style: [{ id: 1 }]
        }
      }
    end

    def radio_img(title, save_name, options, type: "radio_button_img", layout: "horizontal_equal_2")
      items = options.each_with_index.map { |option, index| option.merge(id: index + 1) }
      widths = layout == "vertical" ? ["100"] : ["50", "50"]
      {
        id: 1,
        type: "radio_button",
        radio_button: {
          title_require: !title.to_s.empty?,
          title: title,
          require: true,
          type: type,
          initial_selection: "",
          is_save_input_content: true,
          save_input_content: save_name,
          img_layout: { type: layout, custom_widths: widths },
          option_padding: "0px",
          option_margin: "8px",
          default: [{ id: 1 }],
          radio_button_img: type == "radio_button_img" ? items : [{ id: 1 }],
          upsell_button: type == "upsell_button" ? items : [],
          block_style: [{ id: 1 }]
        }
      }
    end

    def user_html(html)
      {
        id: 1,
        type: "html_code",
        html_code: { content: html, use_for_ugc: false }
      }
    end

    def build(images = {})
      reset_ids!
      profile = cond_or("path", %w[first_time new])
      path_new = cond_is("path", "new")
      path_existing = cond_is("path", "existing")
      pay_credit = cond_is("payment_method", "credit")

      messages = [
        bot_text("I’m PINCH(10ml)7日間お試しキットのご注文を承ります。はじめに、性別をお選びください。"),
        user_message(gender_radio("性別", "gender")),
        user_message(
          radio(
            "ご注文の種類",
            "path",
            [
              { text: "はじめてご注文（会員にならない）", value: "first_time" },
              { text: "新規会員登録して注文", value: "new" },
              { text: "会員ログインして注文", value: "existing" }
            ]
          )
        ),
        bot_text("お客様情報をご入力ください。", conditions: profile),
        user_message(
          text_input("お名前", "user_name", "text", placeholder: "山田", split: true, left: "山田", right: "花子"),
          conditions: profile
        ),
        user_message(
          text_input("メールアドレス", "user_email", "email_address", placeholder: "hanako@impinch.com"),
          text_input("電話番号", "phone_number", "phone_number", placeholder: "09012345678"),
          conditions: profile
        ),
        bot_text("ご住所をご入力ください。", conditions: profile),
        user_message(
          {
            id: 1,
            type: "zip_code_address",
            zip_code_address: {
              title_require: true,
              title: "ご住所",
              is_save_input_content: true,
              save_input_content: "zip_code_address",
              isCheckRequire: "require",
              post_code: "",
              is_use_dropdown: false,
              prefecture: nil,
              municipality: "",
              address: "",
              split_postal_code: false,
              compact_municipality_and_address: false,
              compact_municipality_and_address_and_building_name: false,
              post_code_label: "郵便番号",
              prefecture_label: "都道府県",
              municipality_label: "市区町村",
              address_label: "番地・建物名"
            }
          },
          conditions: profile
        ),
        bot_text("ご生年月日をご入力ください。特典としてお誕生月にお祝いさせていただきます。", conditions: profile),
        user_message(
          {
            id: 1,
            type: "pull_down",
            pull_down: {
              title_require: true,
              title: "生年月日",
              require: true,
              is_save_input_content: true,
              save_input_content: "birth_date",
              type: "dob_ymd",
              customization: {
                initial_selection: "",
                display_unselected: "選択してください",
                is_comment: false,
                options_with_comment: [{ id: 1 }],
                options_without_comment: [{ id: 1 }]
              },
              dob_ymd: {},
              dob_ym: {},
              time_hm: {},
              date_ymd: {},
              date_md: {},
              date_ym: {},
              date_ymd_hm: {},
              timezone_from_to: {},
              period_from_to: {},
              up_to_municipality: {},
              prefectures: {},
              lp_integration_option: {},
              from_js_result: {}
            }
          },
          conditions: profile
        ),
        bot_text("パスワードを設定してください。半角英数字8文字以上です。", conditions: path_new),
        user_message(
          text_input("パスワード", "password", "password", placeholder: "abcd1234"),
          conditions: path_new
        ),
        bot_text("会員規約に同意してください。", conditions: path_new),
        user_message(
          {
            id: 1,
            type: "agree_term",
            agree_term: {
              require: true,
              title_require: true,
              title: "会員規約",
              term: "会員規約に同意します。",
              type: "detail_content",
              detail_content: { content: "会員規約に同意します。" },
              post_link_only: [{}]
            }
          },
          conditions: path_new
        ),
        bot_text("会員の方はログインしてください。お届け先は会員情報の住所を使用します。", conditions: path_existing),
        user_message(
          text_input("メールアドレス（ログインID）", "user_email", "email_address", placeholder: "hanako@impinch.com"),
          conditions: path_existing
        ),
        user_message(
          text_input("パスワード", "password", "password", placeholder: "パスワード"),
          conditions: path_existing
        ),
        bot_text("お支払い方法をお選びください。クレジットカードが便利でおすすめです。"),
        bot_art(images[:pay_promo], "コンビニ後払いとクレジットカード払いの比較"),
        user_message(
          user_image(images[:pay_banner], alt: "お支払い方法"),
          radio(
            "お支払い方法",
            "payment_method",
            [
              { text: "クレジットカード（手数料　0円）", value: "credit" },
              { text: "後払い（コンビニ・郵便局）", value: "gmo_atobarai" }
            ]
          )
        ),
        bot_text(
          "お手持ちのクレジットカード情報を入力してください。※個人情報は暗号化して送信される安心のSSLシステムを採用しています。",
          conditions: pay_credit
        ),
        bot_html(images[:card_brands_html].to_s, conditions: pay_credit),
        user_message(
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
              card_linked_setting: ["credit"],
              initial_selection: "credit",
              radio_contents: [{ id: 1, text: "クレジットカード", value: "credit" }],
              radio_contents_img: [{ id: 1, contents: [{ id: 1 }] }]
            }
          },
          conditions: pay_credit
        ),
        bot_text("最後にサイズを選択してください。"),
        bot_text("山田様、実は特別に大容量サイズもございます。通常価格7,150円ですが、今ならたったの1,980円でご用意ができます。"),
        bot_art(images[:upsell_compare], "アップセル画像"),
        bot_text("下のボタンを押してもまだご注文確定ではありません。ぜひ、お好きなサイズをお選びください。"),
        user_message(
          radio_img(
            "",
            "upsell",
            [
              {
                text: "お試しのまま購入する",
                value: "not_upsell",
                img: images[:upsell_keep],
                alt: "お試しのまま購入する"
              },
              {
                text: "30ml毎月1本お届けコース　初回3,575円（半額）",
                value: "up1",
                img: images[:upsell_30ml],
                alt: "30ml毎月1本お届けコース　初回3,575円（半額）"
              }
            ],
            type: "upsell_button"
          ),
          user_image(images[:upsell_footer], alt: "サイズ比較")
        ),
        bot_text("ありがとうございます。ご注文内容はこちらでよろしいでしょうか？ご確認ください。"),
        bot_text("お届け先は会員情報の住所を使用します。", conditions: path_existing),
        bot_text("カード番号は下4桁のみ表示されます。", conditions: pay_credit),
        user_message(
          user_image(images[:confirm_hero_1], alt: "980_01"),
          user_image(images[:confirm_hero_2], alt: "980_02"),
          user_html(images[:confirm_html].to_s),
          {
            id: 1,
            type: "agree_term",
            agree_term: {
              require: true,
              title_require: true,
              title: "個人情報の取り扱い方について",
              term: "同意する",
              type: "detail_content",
              detail_content: { content: images[:confirm_privacy].to_s },
              post_link_only: [{}]
            }
          },
          {
            id: 1,
            type: "button_submit",
            button_submit_name: "注文を確定する",
            button_submit: {
              title_require: false,
              require: false,
              is_display_error_message: false,
              is_use_js: false,
              is_used_cart_confirm_page: false,
              use_for_confirm_order: false,
              button_image_url: "",
              button_image_width: "80%"
            }
          },
          next_button: false
        )
      ]

      {
        messages: messages,
        urlThanksPage: "",
        urlCartConfirmPage: "",
        isUsedCartConfirmPage: false,
        coupon: "",
        isUseBtnUpdateTracking: false,
        isUseGlobalDelay: false,
        globalDelayTime: nil
      }
    end
  end
end
