# frozen_string_literal: true

module Seeds
  module Templates
    class ConversationBuilder
      AMAZON_PAY_BUTTON = {
        "button_image_url" => Catalog::AMAZON_PAY_BUTTON_IMAGE_URL,
        "button_image_width" => "80%",
        "text_above" => "【Amazon Payで簡単にお買い物！】\nAmazon Payをご利用の方はこちらからどうぞ！",
        "text_below" => "",
        "button_fukushashiki_search_mode" => Catalog::SEARCH_MODE,
        "button_fukushashiki_search_value" => "#AmazonPayCv2Button",
        "button_selector" => "amazon_payment_method"
      }.freeze

      def build(row, order_confirm_config:)
        @next_id = 0
        @amazon_pay = row[:amazon_pay]
        @widget = row[:widget]
        @selectors = row[:selectors]
        messages = []

        messages << bot_text("ようこそ。ご注文手続きを開始します。")
        messages << bot_text("お名前を入力してください。")
        messages << user_name_message
        if @widget[:include_kana]
          messages << bot_text("フリガナを入力してください。")
          messages << user_kana_message
        end
        messages << bot_text("メールアドレスを入力してください。")
        messages << user_email_message
        messages << bot_text("ご住所を入力してください。")
        messages << user_address_message
        messages << bot_text("電話番号を入力してください。")
        messages << user_phone_message
        if @widget[:include_birthday]
          messages << bot_text("生年月日を入力してください。")
          messages.concat(user_birthday_messages)
        end
        if @widget[:include_sex]
          messages << bot_text("性別を選択してください。")
          messages << user_sex_message
        end
        messages << amazon_pay_button_message if @amazon_pay
        messages << bot_text("お支払い方法を選択してください。")
        messages << user_payment_message
        messages << bot_text("カード情報を入力してください。")
        messages << user_card_message
        messages << order_confirm_message(order_confirm_config)
        messages << bot_text("利用規約に同意してください。")
        messages << user_agree_term_message

        {
          "messages" => messages,
          "urlThanksPage" => "",
          "urlCartConfirmPage" => "",
          "isUsedCartConfirmPage" => false,
          "coupon" => "",
          "isUseBtnUpdateTracking" => false,
          "isUseGlobalDelay" => false,
          "globalDelayTime" => nil
        }
      end

      private

      def next_id
        @next_id += 1
      end

      def amazon_display_condition(include_flag)
        {
          "linkCondition" => "and",
          "condition" => include_flag ? "include" : "not_include",
          "nameCondition" => "current_url",
          "inputCondition" => Catalog::AMAZON_PAY_URL_FLAG
        }
      end

      def apply_html_source(message)
        return message unless @amazon_pay

        message["is_used_when_amazon_pay"] = true
        message["conditions"] = [amazon_display_condition(true)]
        message
      end

      def apply_hide_when_amazon(message)
        return message unless @amazon_pay

        message["is_used_when_amazon_pay"] = false
        message["conditions"] = [amazon_display_condition(false)]
        message
      end

      def with_selector(content, key, value)
        return content if value.nil? || value == ""

        content["#{key}_fukushashiki_search_mode"] = Catalog::SEARCH_MODE
        content["#{key}_fukushashiki_search_value"] = value
        content
      end

      def bot_text(content)
        {
          "id" => next_id,
          "hidden" => false,
          "belong_to" => "bot",
          "conditions" => [],
          "message_content" => [
            {
              "type" => "text_input",
              "text_input" => {
                "content" => content,
                "use_for_confirm_message" => false
              },
              "getting_error_notification" => { "use_for_confirm_message" => false },
              "email" => {},
              "file" => {},
              "script" => {},
              "html_code" => {},
              "delay" => { "typing_on" => false },
              "api_link_age" => {},
              "clear_variable" => { "variables" => [] },
              "variable_set" => { "variables" => [] }
            }
          ]
        }
      end

      def user_message(message_name, content, html_source: false, hide_when_amazon: false)
        message = {
          "id" => next_id,
          "hidden" => false,
          "belong_to" => "user",
          "message_name" => message_name,
          "conditions" => [],
          "is_display_button_next" => true,
          "message_content" => [content]
        }
        return apply_html_source(message) if html_source
        return apply_hide_when_amazon(message) if hide_when_amazon

        message
      end

      def text_input_base(title, save_name, type)
        {
          "title_require" => true,
          "title" => title,
          "require" => true,
          "isUseConvertText" => false,
          "isCustomID" => false,
          "convertTextTypeValue" => "katakana",
          "idRefector" => "",
          "is_save_input_content" => true,
          "save_input_content" => save_name,
          "type" => type,
          "text" => {
            "range" => "no_input",
            "isSplitInput" => false,
            "placeholderLeft" => title
          },
          "urls" => {},
          "email_address" => { "placeholder" => "email@example.com" },
          "email_confirmation" => {},
          "phone_number" => {
            "withHyphen" => false,
            "disable_remove_leading_zero" => false,
            "number" => "09012345678"
          },
          "password" => {},
          "password_confirmation" => {}
        }
      end

      def user_name_message
        nested = text_input_base("お名前", "user_name", "text")
        content = { "id" => 1, "type" => "text_input", "text_input" => nested }
        if @widget[:split_name]
          nested["text"]["isSplitInput"] = true
          nested["text"]["placeholderLeft"] = "姓"
          nested["text"]["placeholderRight"] = "名"
          with_selector(content, "left", @selectors[:name_left])
          with_selector(content, "right", @selectors[:name_right])
        else
          content["fukushashiki_search_mode"] = Catalog::SEARCH_MODE
          content["fukushashiki_search_value"] = @selectors[:name]
        end
        user_message("お名前", content, html_source: true)
      end

      def user_kana_message
        nested = text_input_base("フリガナ", "user_name_kana", "text")
        nested["isUseConvertText"] = true
        nested["text"]["isSplitInput"] = true
        nested["text"]["placeholderLeft"] = "セイ"
        nested["text"]["placeholderRight"] = "メイ"
        content = { "id" => 1, "type" => "text_input", "text_input" => nested }
        with_selector(content, "left", @selectors[:kana_left])
        with_selector(content, "right", @selectors[:kana_right])
        user_message("フリガナ", content, html_source: true)
      end

      def user_email_message
        if @widget[:include_email_confirm]
          nested = text_input_base("メールアドレス", "user_email", "email_confirmation")
          content = { "id" => 1, "type" => "text_input", "text_input" => nested }
          with_selector(content, "value", @selectors[:email])
          with_selector(content, "valueConfirm", @selectors[:email_confirm])
          return user_message("メールアドレス", content, html_source: true)
        end

        nested = text_input_base("メールアドレス", "user_email", "email_address")
        content = { "id" => 1, "type" => "text_input", "text_input" => nested }
        content["fukushashiki_search_mode"] = Catalog::SEARCH_MODE
        content["fukushashiki_search_value"] = @selectors[:email]
        user_message("メールアドレス", content, html_source: true)
      end

      def user_address_message
        content = {
          "id" => 1,
          "type" => "zip_code_address",
          "zip_code_address" => {
            "title_require" => true,
            "title" => "ご住所",
            "isCheckRequire" => "require",
            "is_save_input_content" => true,
            "save_input_content" => "user_address",
            "post_code" => "",
            "is_use_dropdown" => false,
            "prefecture" => nil,
            "municipality" => "",
            "address" => "",
            "building_name" => "",
            "split_postal_code" => @widget[:split_zip],
            "compact_municipality_and_address" => false,
            "compact_municipality_and_address_and_building_name" => false,
            "post_code_label" => "郵便番号",
            "prefecture_label" => "都道府県",
            "municipality_label" => "市区町村",
            "address_label" => "番地",
            "building_name_label" => "建物名"
          }
        }
        if @widget[:split_zip]
          with_selector(content, "post_code_left", @selectors[:zip_left])
          with_selector(content, "post_code_right", @selectors[:zip_right])
        else
          with_selector(content, "post_code", @selectors[:zip])
        end
        with_selector(content, "prefecture", @selectors[:prefecture])
        with_selector(content, "municipality", @selectors[:municipality])
        with_selector(content, "address", @selectors[:address])
        with_selector(content, "building_name", @selectors[:building])
        user_message("ご住所", content, html_source: true)
      end

      def user_phone_message
        nested = text_input_base("電話番号", "phone_number", "phone_number")
        content = { "id" => 1, "type" => "text_input", "text_input" => nested }
        if @widget[:split_phone]
          nested["phone_number"]["withHyphen"] = true
          with_selector(content, "value1", @selectors[:tel1])
          with_selector(content, "value2", @selectors[:tel2])
          with_selector(content, "value3", @selectors[:tel3])
        else
          nested["phone_number"]["withHyphen"] = false
          content["fukushashiki_search_mode"] = Catalog::SEARCH_MODE
          content["fukushashiki_search_value"] = @selectors[:tel]
        end
        user_message("電話番号", content, html_source: true)
      end

      def user_birthday_messages
        [
          pull_down_message("生年", "birth_year", @selectors[:birth_year]),
          pull_down_message("生月", "birth_month", @selectors[:birth_month]),
          pull_down_message("生日", "birth_day", @selectors[:birth_day])
        ]
      end

      def pull_down_message(title, save_name, selector)
        content = {
          "id" => 1,
          "type" => "pull_down",
          "fukushashiki_search_mode" => Catalog::SEARCH_MODE,
          "fukushashiki_search_value" => selector,
          "pull_down" => {
            "title_require" => true,
            "title" => title,
            "require" => true,
            "is_save_input_content" => true,
            "save_input_content" => save_name,
            "type" => "customization",
            "customization" => {
              "initial_selection" => "",
              "display_unselected" => "選択してください",
              "is_comment" => false,
              "options_with_comment" => [{ "id" => 1 }],
              "options_without_comment" => [{ "id" => 1 }]
            },
            "time_hm" => {},
            "date_ymd" => {},
            "date_md" => {},
            "date_ym" => {},
            "date_ymd_hm" => {},
            "dob_ymd" => {},
            "dob_ym" => {},
            "timezone_from_to" => {},
            "period_from_to" => {},
            "up_to_municipality" => {},
            "prefectures" => {},
            "lp_integration_option" => {},
            "from_js_result" => {}
          }
        }
        user_message(title, content, html_source: true)
      end

      def user_sex_message
        content = {
          "id" => 1,
          "type" => "radio_button",
          "initial_selection_fukushashiki_search_mode" => Catalog::SEARCH_MODE,
          "initial_selection_fukushashiki_search_value" => @selectors[:sex],
          "radio_button" => {
            "title_require" => true,
            "title" => "性別",
            "require" => true,
            "type" => "default",
            "initial_selection" => 1,
            "is_save_input_content" => true,
            "save_input_content" => "sex",
            "img_layout" => { "type" => "horizontal_equal_2", "custom_widths" => %w[50 50] },
            "option_padding" => "0px",
            "option_margin" => "5px",
            "default" => [
              { "id" => 1, "text" => "男性", "value" => "male" },
              { "id" => 2, "text" => "女性", "value" => "female" }
            ],
            "radio_button_img" => [{ "id" => 1 }],
            "upsell_button" => [
              { "id" => 1, "value" => "アップセルする", "img" => "" },
              { "id" => 2, "value" => "そのまま注文する", "img" => "" }
            ],
            "block_style" => [{ "id" => 1 }]
          }
        }
        user_message("性別", content, html_source: true)
      end

      def amazon_pay_button_message
        {
          "id" => next_id,
          "hidden" => false,
          "belong_to" => "bot",
          "conditions" => [],
          "message_content" => [
            {
              "type" => "amazon_pay_button",
              "amazon_pay_button" => AMAZON_PAY_BUTTON
            }
          ]
        }
      end

      def user_payment_message
        content = {
          "id" => 1,
          "type" => "radio_button",
          "radio_button" => {
            "title_require" => true,
            "title" => "お支払い方法",
            "require" => true,
            "type" => "default",
            "initial_selection" => 1,
            "is_save_input_content" => true,
            "save_input_content" => "payment_method",
            "img_layout" => { "type" => "horizontal_equal_2", "custom_widths" => %w[50 50] },
            "option_padding" => "0px",
            "option_margin" => "5px",
            "default" => [
              { "id" => 1, "text" => "クレジットカード", "value" => "credit_card" },
              { "id" => 2, "text" => "NP後払い", "value" => "np_deferred" }
            ],
            "radio_button_img" => [{ "id" => 1 }],
            "upsell_button" => [
              { "id" => 1, "value" => "アップセルする", "img" => "" },
              { "id" => 2, "value" => "そのまま注文する", "img" => "" }
            ],
            "block_style" => [{ "id" => 1 }]
          }
        }
        user_message("お支払い方法", content, hide_when_amazon: true)
      end

      def user_card_message
        content = {
          "id" => 1,
          "type" => "card_payment_radio_button",
          "card_payment_radio_button" => {
            "is_save_input_content" => true,
            "save_input_content" => "credit_card_payment",
            "require" => true,
            "type" => "default",
            "title_require" => true,
            "title" => "クレジットカード",
            "is_hide_card_name" => false,
            "is_hide_cvc" => false,
            "is_use_installment" => [],
            "separate_type" => false,
            "separate_name" => false,
            "validity_check" => false,
            "type_date_of_expiry" => "ym",
            "payment_method" => [],
            "card_linked_setting" => [],
            "initial_selection" => 1,
            "radio_contents" => [{ "id" => 1, "text" => "クレジットカード", "value" => "credit_card" }],
            "radio_contents_img" => [{ "id" => 1, "contents" => [{ "id" => 1 }] }]
          }
        }
        user_message("クレジットカード", content, hide_when_amazon: true)
      end

      def order_confirm_message(config)
        {
          "id" => next_id,
          "hidden" => false,
          "belong_to" => "bot",
          "conditions" => [],
          "message_content" => [
            {
              "type" => "order_confirm",
              "order_confirm" => config
            }
          ]
        }
      end

      def user_agree_term_message
        content = {
          "id" => 1,
          "type" => "agree_term",
          "agree_term" => {
            "require" => true,
            "title_require" => true,
            "title" => "利用規約",
            "term" => "本サービス利用規約に同意します。",
            "type" => "detail_content",
            "detail_content" => { "content" => "シード用の利用規約です。" },
            "post_link_only" => [{}]
          }
        }
        user_message("利用規約", content)
      end
    end
  end
end
