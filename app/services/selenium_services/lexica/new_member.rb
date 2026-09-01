module SeleniumServices
  module Lexica
    class NewMember < Checkout
      def run_checkout
        open_signup
        fill_signup
        submit_signup
        open_shop
        add_to_cart
        proceed_to_checkout
        login_if_gate_present
        apply_payment_and_submit
      end

      private

      def open_signup
        step("auth_register", "会員登録") do
          navigate signup_url
          wait_element_load S::SIGNUP_FORM
        end
      end

      def fill_signup
        step("fill_customer", "お客様情報") do
          never_click_line
          fill_customer_fields(
            email: S::SIGNUP_EMAIL,
            name1: S::SIGNUP_NAME1,
            name2: S::SIGNUP_NAME2,
            kana1: S::SIGNUP_KANA1,
            kana2: S::SIGNUP_KANA2,
            postal: S::SIGNUP_POSTAL,
            address1: S::SIGNUP_ADDRESS1,
            address2: S::SIGNUP_ADDRESS2,
            address3: S::SIGNUP_ADDRESS3,
            phone: S::SIGNUP_PHONE,
            year: S::SIGNUP_YEAR,
            month: S::SIGNUP_MONTH,
            day: S::SIGNUP_DAY
          )
          raise LexicaStop.new("missing_password", "パスワードがありません") if @password_value.blank?

          fill_to_text_input S::SIGNUP_PASSWORD, @password_value, "password"
        end
      end

      def submit_signup
        step("submit_signup", "同意して会員登録する") do
          raise LexicaStop.new("missing_signup_submit", "会員登録ボタンが見つかりません") unless element_present?(S::SIGNUP_SUBMIT)

          click S::SIGNUP_SUBMIT, "signup submit"
          wait_page_load_complete
          stop_if_already_member
        end
      end

      def login_if_gate_present
        return unless element_present?(S::SIGNIN_FORM)

        step("auth_login", "ログイン") do
          never_click_line
          fill_to_text_input S::SIGNIN_LOGIN_ID, @user_email, "login id"
          fill_to_text_input S::SIGNIN_PASSWORD, @password_value, "password"
          click S::SIGNIN_SUBMIT, "login"
          wait_page_load_complete
          stop_if_login_failed
        end
      end
    end
  end
end
