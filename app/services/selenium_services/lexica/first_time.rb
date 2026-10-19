module SeleniumServices
  module Lexica
    class FirstTime < Checkout
      def run_checkout
        open_shop
        add_to_cart
        proceed_to_checkout
        fill_first_time
        apply_payment_and_submit
      end

      private

      def preferred_submit_selector
        @driver.execute_script(<<~JS)
          var nodes = document.querySelectorAll('button');
          for (var i = 0; i < nodes.length; i++) {
            var oc = nodes[i].getAttribute('onclick') || '';
            var text = (nodes[i].innerText || '').replace(/\\s+/g, '');
            if (text.indexOf('ご注文内容の確認へ') === -1) continue;
            if (oc.indexOf('flg-guest') === -1 || oc.indexOf('true') === -1) continue;
            nodes[i].setAttribute('data-ecch-guest-submit', '1');
            return '[data-ecch-guest-submit="1"]';
          }
          return null;
        JS
      end

      def fill_first_time
        step("auth_first_time", "はじめて入力") do
          never_click_line
          raise LexicaStop.new("missing_first_time_form", "はじめて入力欄が見つかりません") unless element_present?(S::FIRST_TIME_FORM)

          @driver.execute_script("var banner = document.querySelector('.remainWrapper'); if (banner) banner.style.display = 'none';")

          fill_customer_fields(
            email: S::FIRST_TIME_EMAIL,
            name1: S::FIRST_TIME_NAME1,
            name2: S::FIRST_TIME_NAME2,
            kana1: S::FIRST_TIME_KANA1,
            kana2: S::FIRST_TIME_KANA2,
            postal: S::FIRST_TIME_POSTAL,
            address1: S::FIRST_TIME_ADDRESS1,
            address2: S::FIRST_TIME_ADDRESS2,
            address3: S::FIRST_TIME_ADDRESS3,
            phone: S::FIRST_TIME_PHONE,
            year: S::FIRST_TIME_YEAR,
            month: S::FIRST_TIME_MONTH,
            day: S::FIRST_TIME_DAY
          )
          stop_if_already_member
        end
      end
    end
  end
end
