module SeleniumServices
  module Lexica
    class Existing < Checkout
      def run_checkout
        shop_to_checkout
        login_to_order
        apply_payment_and_submit
      end

      private

      def login_to_order
        sign_in(required: true, require_password: true)
      end
    end
  end
end
