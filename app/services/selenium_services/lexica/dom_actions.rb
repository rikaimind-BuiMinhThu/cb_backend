module SeleniumServices
  module Lexica
    module DomActions
      private

            def fill_customer_fields(prefix)
        fill_to_text_input prefix[:email], @user_email, "email" if @user_email.present?
        fill_to_text_input prefix[:name1], @last_name, "last name" if @last_name.present?
        fill_to_text_input prefix[:name2], @first_name, "first name" if @first_name.present?
        fill_to_text_input prefix[:kana1], @last_name_kana, "last name kana" if @last_name_kana.present?
        fill_to_text_input prefix[:kana2], @first_name_kana, "first name kana" if @first_name_kana.present?
        fill_address(prefix)
        fill_to_text_input prefix[:phone], @phone_number, "phone" if @phone_number.present?
        fill_birthday(prefix)
      end


      def fill_address(prefix)
        return if @data_address.blank?

        # Chatbot zip_code_address uses value_* keys; older carts use zip_code / address1..
        postal = @data_address["value_post_code"] || @data_address["zip_code"] ||
          @data_address["zipCode"] || @data_address["post_code"] || @data_address["value"]
        pref = @data_address["value_prefecture"] || @data_address["prefecture"] || @data_address["address1"]
        city = @data_address["value_municipality"] || @data_address["municipality"] ||
          @data_address["city"] || @data_address["address2"]
        street = @data_address["value_address"] || @data_address["address"] ||
          @data_address["town"] || @data_address["address3"] || @data_address["street"]
        fill_to_text_input prefix[:postal], postal, "postal" if postal.present?
        # The cart's postal lookup fills prefecture and city. Overwriting those fails validation.
        wait_for_postal_lookup(prefix[:address1]) if postal.present?
        if input_value(prefix[:address1]).blank?
          fill_to_text_input prefix[:address1], pref, "prefecture" if pref.present?
          fill_to_text_input prefix[:address2], city, "city" if city.present?
        end
        fill_to_text_input prefix[:address3], street, "street" if street.present?
      end


      def wait_for_postal_lookup(address_css)
        Selenium::WebDriver::Wait.new(timeout: 5).until { input_value(address_css).present? }
      rescue Selenium::WebDriver::Error::TimeoutError
        nil
      end


      def input_value(css)
        return "" unless element_present?(css)

        @driver.find_element(css: css).attribute("value").to_s
      rescue Selenium::WebDriver::Error::NoSuchElementError
        ""
      end


      def fill_birthday(prefix)
        return if @birth_date.blank?

        year = @birth_date["yyyy"] || @birth_date["year"] || @birth_date["valueYear"]
        month = @birth_date["mm"] || @birth_date["month"] || @birth_date["valueMonth"]
        day = @birth_date["dd"] || @birth_date["day"] || @birth_date["valueDay"]
        select prefix[:year], year.to_s, "yyyy", "birth year" if year.present? && element_present?(prefix[:year])
        select prefix[:month], month.to_s.rjust(2, "0"), "mm", "birth month" if month.present? && element_present?(prefix[:month])
        select prefix[:day], day.to_s.rjust(2, "0"), "dd", "birth day" if day.present? && element_present?(prefix[:day])
      end


      def fill_to_text_input(css_selector, value, description = "", pointer_action: true)
        record_action(type: "fill", where: css_selector, label: description, value: value)
        logged = description.to_s.downcase.include?("password") ? "********" : value
        @log_tab_level += 1
        Log.info "Fill to text input #{css_selector}: #{description}", @log_tab_level
        input_element = @driver.find_element(css: css_selector)
        begin
          @driver.execute_script("arguments[0].scrollIntoView({block:'center'});", input_element)
          input_element.click
          input_element.clear
          Log.info "input_element.send_keys(#{logged})", @log_tab_level + 1
          input_element.send_keys(value)
          if input_element.attribute("value").to_s.blank?
            raise Selenium::WebDriver::Error::InvalidElementStateError, "value did not stick"
          end
        rescue Selenium::WebDriver::Error::ElementNotInteractableError,
               Selenium::WebDriver::Error::InvalidElementStateError,
               Selenium::WebDriver::Error::ElementClickInterceptedError => e
          Log.info "send_keys failed (#{e.class}); JS value set for #{description}", @log_tab_level + 1
          @driver.execute_script(<<~JS, input_element, value.to_s)
            const el = arguments[0];
            const v = arguments[1];
            el.focus();
            el.value = v;
            el.dispatchEvent(new Event('input', { bubbles: true }));
            el.dispatchEvent(new Event('change', { bubbles: true }));
          JS
        end
        capture
        @log_tab_level -= 1
      end


      def click(css_selector, description = "", pointer_action: true)
        record_action(type: "click", where: css_selector, label: description)
        super(css_selector, description, pointer_action: false)
      end


      def navigate(url)
        record_action(type: "navigate", where: url, label: "navigate")
        super
      end


      def select(css_selector, value, attr_name = "undefined attributes", description = "", pointer_action: true)
        record_action(
          type: "select",
          where: css_selector,
          label: description.presence || attr_name,
          value: value
        )
        super
      end


      def element_present?(css)
        prev = @driver.manage.timeouts.implicit_wait
        @driver.manage.timeouts.implicit_wait = 0
        @driver.find_elements(css: css).any?
      rescue
        false
      ensure
        @driver.manage.timeouts.implicit_wait = prev if defined?(prev) && !prev.nil?
      end


      def click_if_present(css, description)
        return false unless element_present?(css)

        click css, description
        true
      end


      def parse_json_value(raw)
        return {} if raw.blank?
        return raw if raw.is_a?(Hash)

        JSON.parse(raw)
      rescue JSON::ParserError
        {}
      end


      def parse_phone(raw)
        data = parse_json_value(raw)
        return raw.to_s if data.blank? && raw.present?
        return data["value"] if data["value"].present?

        [data["value1"], data["value2"], data["value3"]].compact.join
      end


      def split_name(raw, side)
        data = parse_json_value(raw)
        return nil if data.blank?

        key = side == :left ? "valueLeft" : "valueRight"
        data[key] || data["value"]
      end


      def decode_secret(raw)
        return nil if raw.blank?

        JWT.decode(raw, SECRET_KEY)[0]["data"]
      rescue
        raw
      end


      def hiragana_to_katakana(value)
        value.to_s.tr("ぁ-ゖ", "ァ-ヶ")
      end

      # Lexica furigana fields reject kanji. Convert hiragana; drop values that are not katakana-only.

      def usable_katakana(value)
        return nil if value.blank?

        converted = hiragana_to_katakana(value.to_s.strip)
        return converted if converted.match?(/\A[\p{Katakana}ー\s　]+\z/)

        nil
      end


      def page_contains?(text)
        @driver.page_source.to_s.include?(text)
      end


      def stop_if_already_member
        return unless page_contains?(S::ALREADY_MEMBER_TEXT) || page_contains?("すでに会員")

        Log.info "already member; continue checkout (duplicate email allowed)", @log_tab_level
        record_offer_surface("already_member_continued")
      end


      def stop_if_login_failed
        url = @driver.current_url.to_s
        # Checkout / order pages can still embed a .form-signin widget — do not treat that as failure.
        return if element_present?("#order-entry-content") ||
          element_present?(S::PAYMENT_LIST) ||
          page_contains?("ご入力") ||
          page_contains?("ご確認")
        return unless url.match?(%r{/signin}i)

        failed = page_contains?(S::LOGIN_FAIL_TEXT) ||
          page_contains?("ログインに失敗") ||
          page_contains?("パスワードが違") ||
          page_contains?("ログインできません")
        # Still parked on the dedicated sign-in form after submit.
        failed ||= element_present?(".form-normal-signin input[name=\"LOGIN_ID\"]") ||
          element_present?(".form-order-signin input[name=\"LOGIN_ID\"]")
        raise LexicaStop.new("login_fail", "ログインに失敗しました") if failed
      end


      def sign_in(required:, pointer_action: true, wait_for_loading: false, require_submit: false, require_password: false)
        return unless required || element_present?(S::SIGNIN_FORM)

        step("auth_login", "ログイン") do
          never_click_line
          raise LexicaStop.new("missing_login_form", "ログイン欄が見つかりません") if required && !element_present?(S::SIGNIN_FORM)

          fill_to_text_input S::SIGNIN_LOGIN_ID, @user_email, "login id", pointer_action: pointer_action
          raise LexicaStop.new("missing_password", "パスワードがありません") if require_password && @password_value.blank?

          fill_to_text_input S::SIGNIN_PASSWORD, @password_value, "password", pointer_action: pointer_action
          raise LexicaStop.new("missing_login_submit", "ログインボタンが見つかりません") if require_submit && !element_present?(S::SIGNIN_SUBMIT)

          click S::SIGNIN_SUBMIT, "login", pointer_action: pointer_action
          wait_page_load_complete
          wait_loading_gone if wait_for_loading
          stop_if_login_failed
        end
      end


      def wait_loading_gone(timeout: 30)
        wait = Selenium::WebDriver::Wait.new(timeout: timeout)
        wait.until do
          overlays = @driver.find_elements(css: ".loading, .now-loading, #loading, [class*=\"loading\"]")
          overlays.none?(&:displayed?)
        rescue StandardError
          true
        end
      rescue Selenium::WebDriver::Error::TimeoutError
        Log.info "loading overlay still present after #{timeout}s", @log_tab_level
      end


      def never_click_line
        # Check checkbox first (present on signup). Avoid long wait on missing LINE_LINK.
        return unless element_present?(S::LINE_CHECKBOX) || element_present?(S::LINE_LINK)

        Log.info "LINE control present; not clicking", @log_tab_level
      end


      def find_response_by_data_input_name(data_input_name)
        @conversations
          .select { |conversation| conversation.data_input_name == data_input_name }
          .max_by { |conversation| conversation.id.to_i }
          &.value
      end


      def on_signin?
        @driver.current_url.to_s.include?("/order/signin")
      end


      def visible_form_errors
        @driver.execute_script(<<~JS)
          return Array.from(document.querySelectorAll('#error-msg, .nmessage, .error, .alert, .input-error'))
            .map(function(el) { return (el.textContent || '').replace(/\\s+/g, ' ').trim(); })
            .filter(Boolean)
            .slice(0, 5);
        JS
      end


      def preferred_submit_selector
        nil
      end


      def first_present_selector(css_list)
        css_list.to_s.split(",").map(&:strip).find { |css| element_present?(css) }
      end


      def submit_button_by_text
        S::SUBMIT_ORDER_TEXT.each do |label|
          found = @driver.execute_script(<<~JS, label)
            var nodes = document.querySelectorAll('button, input[type="submit"], a.btn');
            for (var i = 0; i < nodes.length; i++) {
              var t = (nodes[i].innerText || nodes[i].value || '').replace(/\\s+/g, '');
              if (t.indexOf(arguments[0].replace(/\\s+/g, '')) !== -1) {
                if (!nodes[i].id) nodes[i].setAttribute('data-ecch-submit', '1');
                return nodes[i].id ? ('#' + nodes[i].id) : '[data-ecch-submit="1"]';
              }
            }
            return null;
          JS
          return found if found.present?
        end
        nil
      end


    end
  end
end
