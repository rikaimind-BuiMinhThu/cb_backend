module SeleniumServices
  module Lexica
    module Selectors
      CART_VIEW = "#cart-view".freeze
      MAIN_CART = "#main-cart".freeze
      CHECKOUT_BUTTON = "#cart-view button.btn-checkout".freeze
      CHECKOUT_BUTTON_ALT = "#cart-view div.cart-checkout button.btn-checkout".freeze

      FIRST_TIME_FORM = ".form-order-signup".freeze
      FIRST_TIME_BLOCK = ".form-order-signup.form-order-signup-type3".freeze
      FIRST_TIME_EMAIL = ".form-order-signup input[name=\"EMAIL\"]".freeze
      FIRST_TIME_NAME1 = ".form-order-signup input.name1".freeze
      FIRST_TIME_NAME2 = ".form-order-signup input.name2".freeze
      FIRST_TIME_KANA1 = ".form-order-signup input.kana1".freeze
      FIRST_TIME_KANA2 = ".form-order-signup input.kana2".freeze
      FIRST_TIME_POSTAL = ".form-order-signup input[name=\"CUSTOMER_POSTAL_CODE\"]".freeze
      FIRST_TIME_ADDRESS1 = ".form-order-signup input[name=\"CUSTOMER_ADDRESS1\"]".freeze
      FIRST_TIME_ADDRESS2 = ".form-order-signup input[name=\"CUSTOMER_ADDRESS2\"]".freeze
      FIRST_TIME_ADDRESS3 = ".form-order-signup input[name=\"CUSTOMER_ADDRESS3\"]".freeze
      FIRST_TIME_PHONE = ".form-order-signup input[name=\"CUSTOMER_PHONE_NUMBER\"]".freeze
      FIRST_TIME_YEAR = ".form-order-signup select[name=\"yyyy\"]".freeze
      FIRST_TIME_MONTH = ".form-order-signup select[name=\"mm\"]".freeze
      FIRST_TIME_DAY = ".form-order-signup select[name=\"dd\"]".freeze
      FIRST_TIME_ADMAIL = ".form-order-signup input[name=\"ADMAIL_OPT_IN\"]".freeze

      SIGNUP_FORM = "#signup-form".freeze
      SIGNUP_EMAIL = "#signup-form input[name=\"EMAIL\"]".freeze
      SIGNUP_PASSWORD = "#signup-form input[name=\"PASSWORD\"]".freeze
      SIGNUP_NAME1 = "#signup-form input.name1".freeze
      SIGNUP_NAME2 = "#signup-form input.name2".freeze
      SIGNUP_KANA1 = "#signup-form input.kana1".freeze
      SIGNUP_KANA2 = "#signup-form input.kana2".freeze
      SIGNUP_POSTAL = "#signup-form input[name=\"CUSTOMER_POSTAL_CODE\"]".freeze
      SIGNUP_ADDRESS1 = "#signup-form input[name=\"CUSTOMER_ADDRESS1\"]".freeze
      SIGNUP_ADDRESS2 = "#signup-form input[name=\"CUSTOMER_ADDRESS2\"]".freeze
      SIGNUP_ADDRESS3 = "#signup-form input[name=\"CUSTOMER_ADDRESS3\"]".freeze
      SIGNUP_PHONE = "#signup-form input[name=\"CUSTOMER_PHONE_NUMBER\"]".freeze
      SIGNUP_YEAR = "#signup-form select[name=\"yyyy\"]".freeze
      SIGNUP_MONTH = "#signup-form select[name=\"mm\"]".freeze
      SIGNUP_DAY = "#signup-form select[name=\"dd\"]".freeze
      SIGNUP_ADMAIL = "#signup-form input[name=\"ADMAIL_OPT_IN\"]".freeze
      SIGNUP_TERMS = "#terms".freeze
      SIGNUP_SUBMIT = "#signup-form button.btn-submit-signup-canonical".freeze
      GO_SIGNUP = "a.go-signup-to-order".freeze

      # Checkout gate may use form-order-signin; standalone /signin uses form-signin.
      SIGNIN_FORM = ".form-order-signin, .form-normal-signin, .form-signin".freeze
      SIGNIN_LOGIN_ID = ".form-order-signin input[name=\"LOGIN_ID\"], .form-signin input[name=\"LOGIN_ID\"]".freeze
      SIGNIN_PASSWORD = ".form-order-signin input[name=\"PASSWORD\"], .form-signin input[name=\"PASSWORD\"]".freeze
      SIGNIN_SUBMIT = ".form-order-signin button.btn-submit, .form-signin button.btn-submit".freeze
      LINE_CHECKBOX = "input[name=\"LINE_LOGIN_DUMMY_CHECKBOX\"]".freeze
      LINE_LINK = ".form-order-signin a[href*=\"line\"], .form-signin a[href*=\"line\"]".freeze

      PAYMENT_LIST = "#order__payment .payment-method-list".freeze
      DELIVERY_FORM = ".form-deliveryservice".freeze
      DELIVERY_OPTION = ".form-deliveryservice label, .form-deliveryservice input, .form-deliveryservice select option".freeze
      DELIVERY_LABELS = %w[ポスト投函].freeze
      TOKEN_KEY_INPUT = "input[name=\"token_key\"], input[name=\"TOKEN_KEY\"], input#token_key".freeze
      SUBMIT_ORDER = [
        "#order-entry-content #checkout-control div.checkout button.btn-submit",
        "#checkout-control button.btn-submit",
        "button.btn-submit",
        "input.btn-submit[type=\"submit\"]"
      ].join(", ").freeze
      SUBMIT_ORDER_TEXT = ["注文を確定", "この商品を申し込む", "注文する", "購入する"].freeze
      PURCHASE_BLOCKED_HINTS = [
        "在庫がない",
        "限定条件のエラー",
        "購入いただけません",
        "お電話にてお問合せ"
      ].freeze
      THANKS_HINTS = [
        "body#order__complete",
        "body#order_complete",
        ".order-complete",
        "#order-complete"
      ].freeze
      # Fill after MIRAI confirm/thanks screenshots. Blank = skip unless LEXICA_STRICT_OFFERS=1.
      CONFIRM_UPSELL = "".freeze
      THANKS_UPSELL = "".freeze
      THANKS_CROSS_SELL = "".freeze
      ALREADY_MEMBER_TEXT = "既に会員".freeze
      LOGIN_FAIL_TEXT = "ログインできません".freeze
    end
  end
end
