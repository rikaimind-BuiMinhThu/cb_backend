module SeleniumServices
  module Lexica
    class Existing < Checkout
      def run_checkout
        open_shop
        add_to_cart
        proceed_to_checkout
        login_to_order
        apply_payment_and_submit
      end

      private

      def login_to_order
        step("auth_login", "ログイン") do
          never_click_line
          raise LexicaStop.new("missing_login_form", "ログイン欄が見つかりません") unless element_present?(S::SIGNIN_FORM)

          fill_to_text_input S::SIGNIN_LOGIN_ID, @user_email, "login id"
          raise LexicaStop.new("missing_password", "パスワードがありません") if @password_value.blank?

          fill_to_text_input S::SIGNIN_PASSWORD, @password_value, "password"
          click S::SIGNIN_SUBMIT, "login"
          wait_page_load_complete
          stop_if_login_failed
        end
      end
    end
  end
end
