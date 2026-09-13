# frozen_string_literal: true

module Seeds
  module Templates
    module Catalog
      SEARCH_MODE = 2
      AMAZON_PAY_URL_FLAG = "is_using_amazon_pay"
      AMAZON_PAY_BUTTON_IMAGE_URL =
        "https://ec-chatbot.s3.ap-northeast-1.amazonaws.com/uploads/213/86ddda57-14ba-4159-8e75-971a574caec6.png"
      REPEAT_PLUS_PREFIX = "ctl00_ContentPlaceHolder1_ucInputForm_rCartList_ctl00_"

      DEFAULT_AMAZON_DETECTION = {
        "match" => "any",
        "strategies" => [
          { "type" => "url_param", "param" => "amazonCheckoutSessionId" },
          { "type" => "dom_selector", "selector" => "#amazon_payment_method" }
        ],
        "ready_when" => []
      }.freeze

      DETECTIONS = {
        ec_force: {
          "match" => "any",
          "strategies" => [
            { "type" => "dom_selector", "selector" => "#amazon_payment_method" }
          ],
          "ready_when" => [
            { "type" => "dom_value", "selector" => "input#order_shipping_address_attributes_name1" }
          ]
        },
        repeat_plus: {
          "match" => "any",
          "strategies" => [
            { "type" => "url_param", "param" => "amazonCheckoutSessionId" },
            { "type" => "dom_selector", "selector" => "#ctl00_ContentPlaceHolder1_ucInputForm_lbCancelAmazonPay" }
          ],
          "ready_when" => [
            {
              "type" => "dom_value",
              "selector" => "input#ctl00_ContentPlaceHolder1_ucInputForm_rCartList_ctl00_tbOwnerName1"
            }
          ]
        },
        subsc_store: {
          "match" => "any",
          "strategies" => [
            { "type" => "url_param", "param" => "amazonCheckoutSessionId" }
          ],
          "ready_when" => [
            { "type" => "dom_value", "selector" => "input#jsUkProfileFamilyName" }
          ]
        }
      }.freeze

      ECFORCE_SHIPPING_SPLIT = {
        name_left: "order_shipping_address_attributes_name1",
        name_right: "order_shipping_address_attributes_name2",
        zip_left: 'input[name="order[shipping_address_attributes][zip01]"]',
        zip_right: 'input[name="order[shipping_address_attributes][zip02]"]',
        prefecture: "order_shipping_address_attributes_prefecture_name",
        municipality: 'input[name="order[shipping_address_attributes][addr01]"]',
        address: 'input[name="order[shipping_address_attributes][addr02]"]',
        tel1: 'input[name="order[shipping_address_attributes][tel01]"]',
        tel2: 'input[name="order[shipping_address_attributes][tel02]"]',
        tel3: 'input[name="order[shipping_address_attributes][tel03]"]',
        email: "email"
      }.freeze

      ECFORCE_SHIPPING_SINGLE = {
        name: "order_shipping_address_attributes_name1",
        zip: "order_shipping_address_attributes_zip01",
        prefecture: "order_shipping_address_attributes_prefecture_name",
        municipality: "order_shipping_address_attributes_addr01",
        address: "order_shipping_address_attributes_addr02",
        tel: 'input[name="order[shipping_address_attributes][tel01]"]',
        email: 'input[name="order[email]"]'
      }.freeze

      ECFORCE_SHIPPING_SINGLE_KANA = {
        name: 'input[name="order[shipping_address_attributes][name01]"]',
        kana_left: 'input[name="order[shipping_address_attributes][kana01]"]',
        kana_right: 'input[name="order[shipping_address_attributes][kana02]"]',
        zip_left: 'input[name="order[shipping_address_attributes][zip01]"]',
        zip_right: 'input[name="order[shipping_address_attributes][zip02]"]',
        prefecture: 'select[name="order[shipping_address_attributes][prefecture_id]"]',
        municipality: 'input[name="order[shipping_address_attributes][addr01]"]',
        address: 'input[name="order[shipping_address_attributes][addr02]"]',
        tel1: 'input[name="order[shipping_address_attributes][tel01]"]',
        tel2: 'input[name="order[shipping_address_attributes][tel02]"]',
        tel3: 'input[name="order[shipping_address_attributes][tel03]"]',
        email: 'input[name="order[email]"]',
        email_confirm: 'input[name="order[email_confirmation]"]'
      }.freeze

      ECFORCE_BILLING_SPLIT_KANA = {
        name_left: "order_billing_address_attributes_name1",
        name_right: "order_billing_address_attributes_name2",
        kana_left: "order_billing_address_attributes_kana1",
        kana_right: "order_billing_address_attributes_kana2",
        zip_left: "order_billing_address_attributes_zip01",
        zip_right: "order_billing_address_attributes_zip02",
        prefecture: "order_billing_address_attributes_prefecture_name",
        municipality: "order_billing_address_attributes_addr01",
        address: "order_billing_address_attributes_addr02",
        tel1: "order_billing_address_attributes_tel01",
        tel2: "order_billing_address_attributes_tel02",
        tel3: "order_billing_address_attributes_tel03",
        email: 'input[name="order[email]"]'
      }.freeze

      REPEAT_PLUS_OWNER = {
        name_left: "#{REPEAT_PLUS_PREFIX}tbOwnerName1",
        name_right: "#{REPEAT_PLUS_PREFIX}tbOwnerName2",
        kana_left: "#{REPEAT_PLUS_PREFIX}tbOwnerNameKana1",
        kana_right: "#{REPEAT_PLUS_PREFIX}tbOwnerNameKana2",
        birth_year: "#{REPEAT_PLUS_PREFIX}ddlOwnerBirthYear",
        birth_month: "#{REPEAT_PLUS_PREFIX}ddlOwnerBirthMonth",
        birth_day: "#{REPEAT_PLUS_PREFIX}ddlOwnerBirthDay",
        sex: "#{REPEAT_PLUS_PREFIX}rblOwnerSex",
        email: "#{REPEAT_PLUS_PREFIX}tbOwnerMailAddr",
        zip: "#{REPEAT_PLUS_PREFIX}tbOwnerZip",
        prefecture: "#{REPEAT_PLUS_PREFIX}ddlOwnerAddr1",
        municipality: "#{REPEAT_PLUS_PREFIX}tbOwnerAddr2",
        address: "#{REPEAT_PLUS_PREFIX}tbOwnerAddr3",
        building: "#{REPEAT_PLUS_PREFIX}tbOwnerAddr4",
        tel: "#{REPEAT_PLUS_PREFIX}tbOwnerTel1"
      }.freeze

      SUBSC_STORE_PROFILE = {
        name_left: "jsUkProfileFamilyName",
        name_right: "jsUkProfileFirstName",
        kana_left: "jsUkProfileFamilyNameKana",
        kana_right: "jsUkProfileFirstNameKana",
        zip: "jsUkProfileZipCode",
        prefecture: "jsUkProfileStateId",
        municipality: "jsUkProfileCity",
        address: "jsUkProfileStreetAddress",
        tel: "jsUkProfileTel",
        email: "jsUkEmail"
      }.freeze

      WIDGET_SHIPPING_SPLIT = {
        split_name: true,
        include_kana: false,
        include_email_confirm: false,
        split_zip: true,
        split_phone: true,
        include_birthday: false,
        include_sex: false
      }.freeze

      WIDGET_SHIPPING_SINGLE = {
        split_name: false,
        include_kana: false,
        include_email_confirm: false,
        split_zip: false,
        split_phone: false,
        include_birthday: false,
        include_sex: false
      }.freeze

      WIDGET_SHIPPING_SINGLE_KANA = {
        split_name: false,
        include_kana: true,
        include_email_confirm: true,
        split_zip: true,
        split_phone: true,
        include_birthday: false,
        include_sex: false
      }.freeze

      WIDGET_BILLING_SPLIT_KANA = {
        split_name: true,
        include_kana: true,
        include_email_confirm: false,
        split_zip: true,
        split_phone: true,
        include_birthday: false,
        include_sex: false
      }.freeze

      WIDGET_REPEAT_PLUS = {
        split_name: true,
        include_kana: true,
        include_email_confirm: false,
        split_zip: false,
        split_phone: false,
        include_birthday: true,
        include_sex: true
      }.freeze

      WIDGET_SUBSC_STORE = {
        split_name: true,
        include_kana: true,
        include_email_confirm: false,
        split_zip: false,
        split_phone: false,
        include_birthday: false,
        include_sex: false
      }.freeze

      ORDER_CONFIRM_LABELS = {
        "customerSection" => "お客様情報",
        "orderSection" => "ご注文内容",
        "name" => "お名前",
        "address" => "ご住所",
        "productName" => "商品名",
        "unitPrice" => "単価",
        "quantity" => "個数",
        "productSubtotal" => "小計",
        "subtotal" => "小計",
        "deliveryFee" => "送料",
        "charge" => "手数料",
        "tax" => "消費税",
        "total" => "合計",
        "taxNote" => "(10%対象商品小計: {subtotal10}、消費税: {tax10})"
      }.freeze

      ORDER_CONFIRM_DESIGN = {
        "backgroundColor" => "#ffffff",
        "textColor" => "#000000",
        "borderRadiusPx" => 15,
        "paddingPx" => 15,
        "sectionFontSizePx" => 18,
        "sectionColor" => "#000000",
        "sectionFontWeight" => "bold",
        "labelFontSizePx" => 14,
        "labelColor" => "#000000",
        "labelFontWeight" => "bold",
        "valueFontSizePx" => 14,
        "valueColor" => "#444444",
        "valueFontWeight" => "normal",
        "totalColor" => "#000000",
        "totalFontWeight" => "bold",
        "noteFontSizePx" => 13,
        "noteColor" => "#000000",
        "noteFontWeight" => "normal",
        "dividerColor" => "#cccccc"
      }.freeze

      ECFORCE_ORDER_CONFIRM_SELECTORS = {
        "customer" => {
          "name" => ".qa-shipping_address_full_name",
          "address" => ".qa-shipping_address_full_address"
        },
        "product" => {
          "name" => ".qa-product_name",
          "price" => ".qa-product_price",
          "quantity" => ".qa-product_quantity",
          "subtotal" => ".qa-product_subtotal_price"
        },
        "summary" => {
          "subtotal" => ".qa-subtotal",
          "deliveryFee" => ".qa-deliv_fee",
          "charge" => ".qa-charge",
          "tax" => ".qa-tax",
          "total" => ".qa-total"
        },
        "discount" => {
          "subtotal10" => ".qa-subtotal10",
          "tax10" => ".qa-tax10"
        }
      }.freeze

      EMPTY_ORDER_CONFIRM_SELECTORS = {
        "customer" => { "name" => "", "address" => "" },
        "product" => { "name" => "", "price" => "", "quantity" => "", "subtotal" => "" },
        "summary" => { "subtotal" => "", "deliveryFee" => "", "charge" => "", "tax" => "", "total" => "" },
        "discount" => { "subtotal10" => "", "tax10" => "" }
      }.freeze

      ORDER_CONFIRM_FIELD_TEMPLATES = [
        { group: "customer", id: "oc-customer-section", type: "label_only", row_label: "お客様情報（セクション）", label_key: "customerSection", style: "section" },
        { group: "customer", id: "oc-customer-name", type: "paired", row_label: "お名前", label_key: "name", selector_group: "customer", selector_key: "name", preset_key: "customer.name" },
        { group: "customer", id: "oc-customer-address", type: "paired", row_label: "ご住所", label_key: "address", selector_group: "customer", selector_key: "address", preset_key: "customer.address" },
        { group: "product", id: "oc-product-section", type: "label_only", row_label: "ご注文内容（セクション）", label_key: "orderSection", style: "section" },
        { group: "product", id: "oc-product-name", type: "paired", row_label: "商品名", label_key: "productName", selector_group: "product", selector_key: "name", preset_key: "product.name" },
        { group: "product", id: "oc-product-price", type: "paired", row_label: "単価", label_key: "unitPrice", selector_group: "product", selector_key: "price", preset_key: "product.price" },
        { group: "product", id: "oc-product-quantity", type: "paired", row_label: "個数", label_key: "quantity", selector_group: "product", selector_key: "quantity", preset_key: "product.quantity" },
        { group: "product", id: "oc-product-subtotal", type: "paired", row_label: "商品小計", label_key: "productSubtotal", selector_group: "product", selector_key: "subtotal", preset_key: "product.subtotal" },
        { group: "summary", id: "oc-summary-subtotal", type: "paired", row_label: "小計", label_key: "subtotal", selector_group: "summary", selector_key: "subtotal", preset_key: "summary.subtotal" },
        { group: "summary", id: "oc-summary-delivery", type: "paired", row_label: "送料", label_key: "deliveryFee", selector_group: "summary", selector_key: "deliveryFee", preset_key: "summary.deliveryFee" },
        { group: "summary", id: "oc-summary-charge", type: "paired", row_label: "手数料", label_key: "charge", selector_group: "summary", selector_key: "charge", preset_key: "summary.charge" },
        { group: "summary", id: "oc-summary-tax", type: "paired", row_label: "消費税", label_key: "tax", selector_group: "summary", selector_key: "tax", preset_key: "summary.tax" },
        { group: "summary", id: "oc-summary-total", type: "paired", row_label: "合計", label_key: "total", selector_group: "summary", selector_key: "total", preset_key: "summary.total" },
        { group: "discount", id: "oc-discount-subtotal10", type: "selector_only", row_label: "10%対象商品小計", selector_group: "discount", selector_key: "subtotal10", preset_key: "discount.subtotal10" },
        { group: "discount", id: "oc-discount-tax10", type: "selector_only", row_label: "消費税(10%)", selector_group: "discount", selector_key: "tax10", preset_key: "discount.tax10" },
        { group: "discount", id: "oc-discount-tax-note", type: "label_only", row_label: "税注記（{subtotal10}、{tax10}）", label_key: "taxNote", style: "note" }
      ].freeze

      module_function

      def extra_config(cart, amazon_pay:)
        {
          "is_use_amazon_pay" => amazon_pay,
          "allowed_lp_domains" => [],
          "lp_integration_mode" => amazon_pay ? "generic" : "auto",
          "amazon_pay_config" => {
            "poll_interval_ms" => 200,
            "max_count" => 20,
            "amazon_detection" => amazon_pay ? DETECTIONS.fetch(cart) : DEFAULT_AMAZON_DETECTION
          }
        }
      end

      def order_confirm_config(lp_preset, selectors)
        {
          "lp_preset" => lp_preset,
          "preview_root_selector" => "#preview-view",
          "retry" => { "maxRetry" => 20, "delay" => 500 },
          "error_message" => "入力エラーが発生しています。修正の上、再度お試しください。",
          "scroll_auto" => false,
          "selectors" => selectors,
          "labels" => ORDER_CONFIRM_LABELS,
          "design" => ORDER_CONFIRM_DESIGN,
          "fields_by_group" => fields_by_group(selectors)
        }
      end

      def fields_by_group(selectors)
        groups = { "customer" => [], "product" => [], "summary" => [], "discount" => [] }
        ORDER_CONFIRM_FIELD_TEMPLATES.each do |template|
          field = {
            "id" => template[:id],
            "type" => template[:type],
            "rowLabel" => template[:row_label],
            "label" => ORDER_CONFIRM_LABELS[template[:label_key]] || "",
            "selector" => ""
          }
          field["preset_key"] = template[:preset_key] if template[:preset_key]
          field["style"] = template[:style] if template[:style]
          if template[:selector_group] && template[:selector_key]
            field["selector"] = selectors.dig(template[:selector_group], template[:selector_key]) || ""
          end
          groups[template[:group]] << field
        end
        groups
      end

      def scenario_row(name:, cart:, amazon_pay:, widget:, selectors:, order_confirm_key:)
        {
          name: name,
          cart: cart,
          amazon_pay: amazon_pay,
          widget: widget,
          selectors: selectors,
          order_confirm_key: order_confirm_key,
          extra_config: extra_config(cart, amazon_pay: amazon_pay)
        }
      end

      def scenario_rows
        [
          scenario_row(
            name: "EC Force（AmazonPay対応：配送先・分割氏名）",
            cart: :ec_force,
            amazon_pay: true,
            widget: WIDGET_SHIPPING_SPLIT,
            selectors: ECFORCE_SHIPPING_SPLIT,
            order_confirm_key: :ec_force
          ),
          scenario_row(
            name: "EC Force（AmazonPay対応：配送先・氏名一体）",
            cart: :ec_force,
            amazon_pay: true,
            widget: WIDGET_SHIPPING_SINGLE,
            selectors: ECFORCE_SHIPPING_SINGLE,
            order_confirm_key: :ec_force
          ),
          scenario_row(
            name: "EC Force（AmazonPay対応：配送先・氏名一体+カナ）",
            cart: :ec_force,
            amazon_pay: true,
            widget: WIDGET_SHIPPING_SINGLE_KANA,
            selectors: ECFORCE_SHIPPING_SINGLE_KANA,
            order_confirm_key: :ec_force
          ),
          scenario_row(
            name: "EC Force（AmazonPay対応：請求先・分割氏名+カナ）",
            cart: :ec_force,
            amazon_pay: true,
            widget: WIDGET_BILLING_SPLIT_KANA,
            selectors: ECFORCE_BILLING_SPLIT_KANA,
            order_confirm_key: :ec_force
          ),
          scenario_row(
            name: "EC Force（AmazonPay非対応）",
            cart: :ec_force,
            amazon_pay: false,
            widget: WIDGET_SHIPPING_SPLIT,
            selectors: ECFORCE_SHIPPING_SPLIT,
            order_confirm_key: :ec_force
          ),
          scenario_row(
            name: "リピートPLUS（AmazonPay対応：購入者・分割氏名+カナ）",
            cart: :repeat_plus,
            amazon_pay: true,
            widget: WIDGET_REPEAT_PLUS,
            selectors: REPEAT_PLUS_OWNER,
            order_confirm_key: :repeat_plus
          ),
          scenario_row(
            name: "リピートPLUS（AmazonPay非対応）",
            cart: :repeat_plus,
            amazon_pay: false,
            widget: WIDGET_REPEAT_PLUS,
            selectors: REPEAT_PLUS_OWNER,
            order_confirm_key: :repeat_plus
          ),
          scenario_row(
            name: "サブスクストア（AmazonPay対応：プロフィール・分割氏名+カナ）",
            cart: :subsc_store,
            amazon_pay: true,
            widget: WIDGET_SUBSC_STORE,
            selectors: SUBSC_STORE_PROFILE,
            order_confirm_key: :subsc_store
          ),
          scenario_row(
            name: "サブスクストア（AmazonPay非対応）",
            cart: :subsc_store,
            amazon_pay: false,
            widget: WIDGET_SUBSC_STORE,
            selectors: SUBSC_STORE_PROFILE,
            order_confirm_key: :subsc_store
          )
        ]
      end

      def order_confirm_rows
        [
          {
            key: :ec_force,
            name: "EC Force",
            config: order_confirm_config("ecforce", ECFORCE_ORDER_CONFIRM_SELECTORS)
          },
          {
            key: :repeat_plus,
            name: "リピートPLUS",
            config: order_confirm_config("custom", EMPTY_ORDER_CONFIRM_SELECTORS)
          },
          {
            key: :subsc_store,
            name: "サブスクストア",
            config: order_confirm_config("custom", EMPTY_ORDER_CONFIRM_SELECTORS)
          }
        ]
      end
    end
  end
end
