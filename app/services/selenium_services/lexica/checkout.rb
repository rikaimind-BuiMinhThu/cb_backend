require "selenium-webdriver"
require "base64"
require "json"
require "uri"
require File.dirname(__FILE__) + "/../../log"
require File.dirname(__FILE__) + "/../../captcha/two_captcha"

module SeleniumServices
  module Lexica
    class Checkout < SeleniumServices::Lexica::Base
      S = Selectors
      PATH_NAME = nil
      RECAPTCHA_MARK = "リキャプチャ".freeze
      RECAPTCHA_SOLVE_MAX_ATTEMPTS = 5
      RECAPTCHA_FAIL_HINTS = [
        RECAPTCHA_MARK,
        "Fail to verify ReCaptcha",
        "Fail to verify Recaptcha",
        "fail to verify recaptcha",
      ].freeze

      def process
        @log_tab_level += 1
        Log.info "Start lexica #{self.class.name}", @log_tab_level
        snapshot_scenario_urls
        begin
          apply_resolved_offers
          run_checkout
          mark_done
        rescue OfferError, LexicaStop => e
          fail_result(e.error_kind, e.message)
        rescue => e
          Log.error e.message
          Log.error e.backtrace.join("\n\t")
          fail_result("rpa_error", e.message)
        ensure
          begin
            quit
          rescue => quit_error
            Log.error "driver.quit failed: #{quit_error.message}"
          end
        end
      end

      private

      class LexicaStop < StandardError
        attr_reader :error_kind

        def initialize(error_kind, message)
          @error_kind = error_kind
          super(message)
        end
      end

      def run_checkout
        raise NotImplementedError, "#{self.class} must implement run_checkout"
      end

      def extract_conversions_data
        @user_email = find_response_by_data_input_name("user_email").presence || find_response_by_data_input_name("email")
        @last_name = split_name(find_response_by_data_input_name("user_name"), :left) || find_response_by_data_input_name("last_name")
        @first_name = split_name(find_response_by_data_input_name("user_name"), :right) || find_response_by_data_input_name("first_name")
        # I'm PINCH has no kana step; Lexica requires katakana. Hiragana→katakana only; never copy kanji.
        @last_name_kana = usable_katakana(
          split_name(find_response_by_data_input_name("user_name_kana"), :left) ||
            find_response_by_data_input_name("last_name_kana")
        ).presence || usable_katakana(@last_name)
        @first_name_kana = usable_katakana(
          split_name(find_response_by_data_input_name("user_name_kana"), :right) ||
            find_response_by_data_input_name("first_name_kana")
        ).presence || usable_katakana(@first_name)
        @data_address = parse_json_value(find_response_by_data_input_name("zip_code_address"))
        @phone_number = parse_phone(find_response_by_data_input_name("phone_number") || find_response_by_data_input_name("phone"))
        @birth_date = parse_json_value(find_response_by_data_input_name("birth_date"))
        @quantity_value = find_response_by_data_input_name("quantity")
        @payment_method = normalize_payment(find_response_by_data_input_name("payment_method"))
        @credit_card_payment = find_response_by_data_input_name("credit_card_payment")
        @card_data = decode_card(@credit_card_payment)
        encrypted_password_value = find_response_by_data_input_name("password")
        @password_value = decode_secret(encrypted_password_value)
        @path = SeleniumServices::Lexica.extract_path(@conversations)
        @sku = @scenario.merchandise_id.to_s
        @product_url = @scenario.landing_page_product_url.to_s
        @cart_url = @scenario.lexica_cart_url.to_s
        @cart_skus = [@sku].reject(&:blank?)
        @offer_surfaces = []
        @token_key = @card_data && (@card_data["token_key"] || @card_data[:token_key])
      end

      def apply_resolved_offers
        resolved = OfferResolver.new(@scenario, @conversations).resolve!
        @sku = resolved.sku
        @product_url = resolved.product_url
        @cart_skus = resolved.cart_skus
        @offer_surfaces = resolved.surfaces.dup
        @cross_sell_sku = resolved.cross_sell_sku
        snapshot_scenario_urls
      end

      def snapshot_scenario_urls
        attrs = {
          path: @path,
          payment: @payment_method,
          sku: @sku,
          product_url: @product_url,
          cart_url: @cart_url,
          masked_pan: masked_pan_from_card,
          card_expiry: card_expiry_from_card,
          card_holder: card_holder_from_card,
          token_key: nil
        }
        attrs[:resolved_sku] = @sku if @selenium_result&.respond_to?(:resolved_sku)
        attrs[:resolved_product_url] = @product_url if @selenium_result&.respond_to?(:resolved_product_url)
        attrs[:offer_surfaces] = JSON.generate(Array(@offer_surfaces)) if @selenium_result&.respond_to?(:offer_surfaces)
        @selenium_result&.update!(attrs)
      end

      def open_shop
        step("open_shop", "ショップを開く") do
          raise LexicaStop.new("missing_product_url", "商品URLが未設定です") if @product_url.blank?

          navigate @product_url
          wait_page_load_complete
        end
      end

      def add_to_cart
        step("add_to_cart", "カートに入れる") do
          raise LexicaStop.new("missing_sku", "SKUが未設定です") if @cart_skus.blank?

          @cart_skus.each { |sku| add_sku_to_cart(sku) }
          # #cart-view is on the cart host, not the LP. After AddItemToCart, ensure we are there.
          unless element_present?(S::CART_VIEW)
            navigate "#{cart_base_url}/"
            wait_page_load_complete
          end
          wait_element_load S::CART_VIEW
          reject_unknown_sku
        end
      end

      def reject_unknown_sku
        return unless @driver.page_source.to_s.include?("商品が見つかりません")

        raise LexicaStop.new("missing_sku", "商品コード（#{@cart_skus.join(",")}）の商品が見つかりません")
      end

      def add_sku_to_cart(sku)
        href = add_to_cart_href_for(sku)
        # Prefer cart-host AddItemToCart navigation — LP often has no window.n / #cart-view.
        if click_if_present(%(a[href="#{href}"]), "Add SKU #{sku}")
          wait_page_load_complete
          return
        end
        if @driver.execute_script("return !!(window.n && n.addItemToCart);")
          execute_script("n.addItemToCart(#{sku.to_json}, 1);")
          wait_page_load_complete
          return
        end

        navigate href
        wait_page_load_complete
      end

      def proceed_to_checkout
        step("proceed_to_checkout", "レジへ") do
          wait_element_load S::CART_VIEW
          if element_present?(S::CHECKOUT_BUTTON)
            click S::CHECKOUT_BUTTON, "checkout"
          elsif element_present?(S::CHECKOUT_BUTTON_ALT)
            click S::CHECKOUT_BUTTON_ALT, "checkout alt"
          else
            raise LexicaStop.new("empty_cart", "カートが空のためレジに進めません")
          end
          wait_page_load_complete
        end
      end

      def shop_to_checkout
        open_shop
        add_to_cart
        proceed_to_checkout
      end

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

      def apply_payment_and_submit
        apply_payment
        apply_delivery
        apply_confirm_upsell
        submit_order
        detect_thanks
        apply_thanks_offers
      end

      def apply_confirm_upsell
        return unless offer_flag?(:lexica_offer_confirm_upsell)

        upsell_sku = @scenario.lexica_upsell_sku.to_s
        if upsell_sku.present? && @cart_skus.include?(upsell_sku)
          record_offer_surface("confirm_upsell_skipped")
          return
        end

        click_offer_or_defer(
          selector: S::CONFIRM_UPSELL,
          surface: "confirm_upsell",
          missing_kind: "confirm_upsell_missing",
          missing_message: "確認画面のアップセルが見つかりません",
          sku: upsell_sku
        )
      end

      def apply_thanks_offers
        if offer_flag?(:lexica_offer_thanks_upsell)
          click_offer_or_defer(
            selector: S::THANKS_UPSELL,
            surface: "thanks_upsell",
            missing_kind: "thanks_upsell_missing",
            missing_message: "サンクス画面のアップセルが見つかりません",
            sku: @scenario.lexica_upsell_sku.to_s
          )
        end
        return unless offer_flag?(:lexica_offer_thanks_cross_sell)

        click_offer_or_defer(
          selector: S::THANKS_CROSS_SELL,
          surface: "thanks_cross_sell",
          missing_kind: "thanks_cross_sell_missing",
          missing_message: "サンクス画面のクロスセルが見つかりません",
          sku: @scenario.lexica_cross_sell_sku.to_s
        )
      end

      def click_offer_or_defer(selector:, surface:, missing_kind:, missing_message:, sku:)
        if selector.to_s.blank?
          record_offer_surface("#{surface}_awaiting_selector")
          if ENV["LEXICA_STRICT_OFFERS"] == "1"
            raise LexicaStop.new(missing_kind, missing_message)
          end
          return
        end

        step(surface, surface) do
          unless element_present?(selector)
            raise LexicaStop.new(missing_kind, missing_message)
          end

          click selector, surface
          @cart_skus << sku if sku.present? && !@cart_skus.include?(sku)
          record_offer_surface(surface)
        end
      end

      def offer_flag?(name)
        return false unless @scenario.respond_to?(name)

        ActiveModel::Type::Boolean.new.cast(@scenario.public_send(name))
      end

      def record_offer_surface(name)
        @offer_surfaces = Array(@offer_surfaces) | [name]
        return unless @selenium_result&.respond_to?(:offer_surfaces)

        @selenium_result.update!(offer_surfaces: JSON.generate(@offer_surfaces))
      end

      def apply_payment
        name =
          case @payment_method
          when "credit" then "payment_credit"
          when "gmo_atobarai" then "payment_gmo_atobarai"
          else
            raise LexicaStop.new("unknown_payment", "支払い方法が不正です: #{@payment_method.inspect}")
          end
        step(name, "支払い") do
          wait_page_load_complete
          if element_present?(S::PAYMENT_LIST) || element_present?(".payment-method-name label")
            click_payment_option
          end
          if @payment_method == "credit"
            inject_token_key
          else
            Log.info "GMO: no credit-auth wait", @log_tab_level
          end
        end
      end

      def click_payment_option
        labels = payment_option_labels
        labels.each do |label|
          clicked = @driver.execute_script(<<~JS, label)
            var nodes = document.querySelectorAll('#order__payment label, #order__payment .payment-method-list label, #order__payment input, .payment-method-name label');
            for (var i = 0; i < nodes.length; i++) {
              var t = (nodes[i].innerText || nodes[i].value || '');
              if (t.indexOf(arguments[0]) !== -1) {
                nodes[i].click();
                return true;
              }
            }
            return false;
          JS
          if clicked
            record_action(type: "click", where: "#order__payment", label: "payment #{label}")
            break
          end
        end
      end

      def payment_option_labels
        case @payment_method
        when "credit" then %w[クレジットカード ZEUS]
        when "gmo_atobarai" then %w[GMO後払い 後払い]
        else
          raise LexicaStop.new("unknown_payment", "支払い方法が不正です: #{@payment_method.inspect}")
        end
      end

      def inject_token_key
        raise LexicaStop.new("missing_token", "カードトークンがありません") if @token_key.blank?

        if element_present?(S::TOKEN_KEY_INPUT)
          fill_to_text_input S::TOKEN_KEY_INPUT, @token_key, "token_key"
        else
          execute_script(<<~JS)
            (function() {
              var el = document.querySelector('input[name="token_key"]') || document.querySelector('input[name="TOKEN_KEY"]');
              if (!el) {
                el = document.createElement('input');
                el.type = 'hidden';
                el.name = 'token_key';
                var form = document.querySelector('form') || document.body;
                form.appendChild(el);
              }
              el.value = #{@token_key.to_json};
            })();
          JS
        end
      end

      def apply_delivery
        step("fill_delivery", "お届け") do
          if element_present?(S::DELIVERY_FORM)
            click_delivery_option
          end
          true
        end
      end

      def click_delivery_option
        S::DELIVERY_LABELS.each do |label|
          clicked = @driver.execute_script(<<~JS, label)
            var nodes = document.querySelectorAll(#{S::DELIVERY_OPTION.to_json});
            for (var i = 0; i < nodes.length; i++) {
              var t = (nodes[i].innerText || nodes[i].value || '');
              if (t.indexOf(arguments[0]) !== -1) {
                nodes[i].click();
                return true;
              }
            }
            return false;
          JS
          break if clicked
        end
      end

      def submit_order
        never_click_line
        blocked = S::PURCHASE_BLOCKED_HINTS.find { |hint| page_contains?(hint) }
        if blocked
          raise LexicaStop.new(
            "purchase_blocked",
            "Lexicaが購入を拒否しました（#{blocked}）。SKU/在庫/限定条件を確認してください"
          )
        end

        selector = preferred_submit_selector
        selector = first_present_selector(S::SUBMIT_ORDER) || submit_button_by_text if selector.blank?
        raise LexicaStop.new("missing_submit", "注文確定ボタンが見つかりません") if selector.blank?

        v3_meta = nil
        step("recaptcha_v3_detect", "reCAPTCHA v3 検出") do
          v3_meta = detect_recaptcha_v3_meta
          if v3_meta[:present]
            record_action(
              type: :detect,
              where: "api.js?render=",
              label: "sitekey",
              value: truncate_sitekey(v3_meta[:sitekey])
            )
            record_action(type: :detect, where: "grecaptcha.execute", label: "action", value: v3_meta[:action]) if v3_meta[:action].present?
          else
            record_action(type: :detect, where: "page", label: "recaptcha_v3", value: "なし → 2Captchaスキップ")
          end
        end

        if v3_meta[:present]
          submit_order_with_two_captcha!(selector, v3_meta)
        else
          step("submit_order", "注文確定") do
            click selector, "submit order"
            wait_for_checkout_progress
            if on_signin?
              errors = Array(visible_form_errors)
              raise LexicaStop.new("form_invalid", errors.presence&.join(" / ") || "確認画面へ進めませんでした")
            end
            confirm_review_page
          end
        end
      end

      def submit_order_with_two_captcha!(selector, v3_meta)
        sitekey = v3_meta[:sitekey].to_s
        raise LexicaStop.new("recaptcha", "reCAPTCHA v3 sitekey不明") if sitekey.blank?

        action = v3_meta[:action].presence || "verify"
        client = Captcha::TwoCaptcha.new(log_tab_level: @log_tab_level)
        last_message = nil

        RECAPTCHA_SOLVE_MAX_ATTEMPTS.times do |index|
          attempt = index + 1
          task_id = nil
          begin
            step("recaptcha_v3", "reCAPTCHA v3 試行 #{attempt}/#{RECAPTCHA_SOLVE_MAX_ATTEMPTS}") do
              result = client.process_v3(
                sitekey: sitekey,
                page_url: @driver.current_url,
                action: action,
                min_score: 0.9
              )
              task_id = result[:id]
              record_action(
                type: :"2captcha",
                where: "in.php",
                label: "create",
                request: result[:create_request],
                response: result[:create_response]
              )
              record_action(
                type: :"2captcha",
                where: "res.php",
                label: "get",
                request: result[:get_request],
                response: result[:get_response]
              )
              inject_recaptcha_token(result[:token])
              record_recaptcha_diag!(
                "after_inject",
                result[:token],
                expected_action: action,
                page_host: (URI.parse(@driver.current_url.to_s).host rescue nil)
              )
              record_action(
                type: :detect,
                where: "dom",
                label: "pre_click",
                request: recaptcha_field_snapshot
              )
              click selector, "submit order 2captcha attempt #{attempt}"
              wait_for_checkout_progress

              form_errors = Array(visible_form_errors)
              if on_signin? && non_recaptcha_form_errors?(form_errors)
                record_action(
                  type: :detect,
                  where: (@driver.current_url rescue "unknown"),
                  label: "form_invalid",
                  request: {
                    "page_message" => recaptcha_page_message,
                    "form_errors" => form_errors,
                    "fields" => recaptcha_field_snapshot
                  }
                )
                raise LexicaStop.new("form_invalid", form_errors.join(" / "))
              end

              if recaptcha_submit_failed?
                record_action(
                  type: :detect,
                  where: (@driver.current_url rescue "unknown"),
                  label: "reject",
                  request: {
                    "page_message" => recaptcha_page_message,
                    "form_errors" => form_errors,
                    "fields" => recaptcha_field_snapshot
                  }
                )
                report_io = client.report(task_id, good: false)
                record_two_captcha_report!("reportbad", report_io)
                last_message = recaptcha_stop_message
                raise LexicaStop.new("recaptcha", last_message)
              end

              report_io = client.report(task_id, good: true)
              record_two_captcha_report!("reportgood", report_io)
              confirm_review_page
            end
            return
          rescue LexicaStop => e
            raise unless e.error_kind.to_s == "recaptcha"

            last_message = e.message
            Log.info "reCAPTCHA v3 attempt #{attempt}/#{RECAPTCHA_SOLVE_MAX_ATTEMPTS} failed: #{e.message}", @log_tab_level
            raise if attempt >= RECAPTCHA_SOLVE_MAX_ATTEMPTS
          rescue StandardError => e
            last_message = e.message
            if task_id.present?
              report_io = client.report(task_id, good: false)
              record_two_captcha_report!("reportbad", report_io)
            end
            Log.info "reCAPTCHA v3 attempt #{attempt}/#{RECAPTCHA_SOLVE_MAX_ATTEMPTS} failed: #{e.message}", @log_tab_level
            raise LexicaStop.new("recaptcha", last_message) if attempt >= RECAPTCHA_SOLVE_MAX_ATTEMPTS
          end
        end

        raise LexicaStop.new(
          "recaptcha",
          last_message.presence || "reCAPTCHA (2Captcha #{RECAPTCHA_SOLVE_MAX_ATTEMPTS}回失敗)"
        )
      end

      def record_two_captcha_report!(label, report_io)
        return if report_io.blank?

        record_action(
          type: :"2captcha",
          where: "res.php",
          label: label,
          request: report_io[:request],
          response: report_io[:response]
        )
      end

      def wait_for_checkout_progress
        Selenium::WebDriver::Wait.new(timeout: 45).until do
          !on_signin? || visible_form_errors.any? || recaptcha_page_message.present? || recaptcha_token_present?
        end
      rescue Selenium::WebDriver::Error::TimeoutError
        nil
      end

      def on_signin?
        @driver.current_url.to_s.include?("/order/signin")
      end

      def recaptcha_stop_message
        recaptcha_page_message.presence || "reCAPTCHAの検証が実行されました"
      end

      def recaptcha_page_message
        visible = Array(visible_form_errors).find { |error| error.to_s.include?(RECAPTCHA_MARK) }
        return visible if visible.present?
        return RECAPTCHA_MARK if page_contains?(RECAPTCHA_MARK)

        nil
      end

      def recaptcha_token_present?
        @driver.execute_script(<<~JS)
          var el = document.querySelector('textarea[name="g-recaptcha-response"], #g-recaptcha-response');
          return !!(el && el.value && el.value.length > 20);
        JS
      rescue
        false
      end

      def detect_recaptcha_v3_meta
        meta = @driver.execute_script(<<~JS)
          var result = { present: false, sitekey: null };
          var scripts = document.querySelectorAll('script[src*="recaptcha/api.js"]');
          for (var i = 0; i < scripts.length; i++) {
            var src = scripts[i].src || '';
            var m = src.match(/[?&]render=([^&]+)/);
            if (m && m[1] && m[1] !== 'explicit') {
              result.present = true;
              result.sitekey = decodeURIComponent(m[1]);
              break;
            }
          }
          try {
            if (window.___grecaptcha_cfg && ___grecaptcha_cfg.clients && ___grecaptcha_cfg.clients[100000]) {
              result.present = true;
            }
          } catch (e) {}
          var tokenField = document.querySelector('input[name="RECAPTCHA_TOKEN"], textarea[name="RECAPTCHA_TOKEN"]');
          if (tokenField) result.present = true;
          var dataEl = document.querySelector('[data-sitekey]');
          if (dataEl && dataEl.getAttribute('data-sitekey')) {
            result.present = true;
            if (!result.sitekey) result.sitekey = dataEl.getAttribute('data-sitekey');
          }
          return result;
        JS
        meta = meta.is_a?(Hash) ? meta.stringify_keys : {}
        sitekey = meta["sitekey"].to_s.presence
        present = meta["present"] == true || sitekey.present?
        {
          present: present,
          sitekey: sitekey,
          action: extract_recaptcha_action
        }
      rescue StandardError => e
        Log.error "detect_recaptcha_v3_meta: #{e.message}", @log_tab_level
        { present: false, sitekey: nil, action: nil }
      end

      def extract_recaptcha_action
        action = @driver.execute_script(<<~JS)
          try {
            var html = document.documentElement && document.documentElement.outerHTML || '';
            var m = html.match(/grecaptcha\\.execute\\s*\\(\\s*['\"][^'\"]+['\"]\\s*,\\s*\\{\\s*action\\s*:\\s*['\"]([^'\"]+)['\"]/);
            if (m) return m[1];
            m = html.match(/action\\s*:\\s*['\"]([a-zA-Z0-9_/-]+)['\"]/);
            return m ? m[1] : null;
          } catch (e) { return null; }
        JS
        action.to_s.presence
      rescue
        nil
      end

      def inject_recaptcha_token(token)
        @driver.execute_script(<<~JS, token)
          var t = arguments[0];
          window.grecaptcha = window.grecaptcha || {};
          window.grecaptcha.ready = function(cb) { if (typeof cb === 'function') { cb(); } };
          window.grecaptcha.execute = function() { return Promise.resolve(t); };
          ['RECAPTCHA_TOKEN', 'g-recaptcha-response'].forEach(function(name) {
            var el = document.querySelector('[name=\"' + name + '\"]');
            if (!el) {
              el = document.createElement(name === 'g-recaptcha-response' ? 'textarea' : 'input');
              if (name !== 'g-recaptcha-response') el.type = 'hidden';
              el.name = name;
              el.id = name === 'g-recaptcha-response' ? 'g-recaptcha-response' : el.id;
              var form = document.querySelector('form') || document.body;
              form.appendChild(el);
            }
            el.value = t;
            if (el.innerHTML !== undefined && name === 'g-recaptcha-response') el.innerHTML = t;
          });
        JS
      end

      def record_recaptcha_diag!(label, raw_token, expected_action:, page_host:)
        token = raw_token.to_s
        claims = decode_recaptcha_token_claims(token)
        record_action(
          type: :detect,
          where: "dom",
          label: label,
          request: {
            "length" => token.length,
            "preview" => token_preview(token),
            "expected_action" => expected_action.to_s,
            "page_host" => page_host.to_s,
            "claims" => claims,
            "action_match" => claims["action"].blank? || claims["action"].to_s == expected_action.to_s,
            "hostname_match" => claims["hostname"].blank? || claims["hostname"].to_s == page_host.to_s,
            "fields" => recaptcha_field_snapshot
          }
        )
      end

      def recaptcha_field_snapshot
        snap = @driver.execute_script(<<~JS)
          var out = { fields: {}, form_names: [] };
          ['RECAPTCHA_TOKEN', 'g-recaptcha-response'].forEach(function(name) {
            var els = document.querySelectorAll('[name=\"' + name + '\"]');
            out.fields[name] = {
              count: els.length,
              lengths: Array.prototype.map.call(els, function(el) {
                return (el.value || el.innerHTML || '').length;
              })
            };
          });
          var form = document.querySelector('form');
          if (form) {
            Array.prototype.forEach.call(form.elements || [], function(el) {
              var n = el.name || '';
              if (/recaptcha/i.test(n)) out.form_names.push(n);
            });
          }
          return out;
        JS
        snap.is_a?(Hash) ? snap.stringify_keys : { "raw" => snap.to_s }
      rescue StandardError => e
        { "error" => e.message }
      end

      def decode_recaptcha_token_claims(token)
        parts = token.to_s.split(".")
        return { "shape" => "not_jwt", "parts" => parts.length } if parts.length < 2

        payload = parts[1].to_s
        padded = payload.ljust(payload.length + (4 - payload.length % 4) % 4, "=")
        json = Base64.urlsafe_decode64(padded)
        data = JSON.parse(json)
        {
          "shape" => "jwt_like",
          "action" => data["action"],
          "hostname" => data["hostname"] || data["host"],
          "apk_package_name" => data["apk_package_name"],
          "keys" => data.keys.first(20)
        }
      rescue StandardError => e
        { "shape" => "decode_failed", "error" => e.message, "parts" => parts&.length }
      end

      def token_preview(token)
        text = token.to_s
        return text if text.length <= 28

        "#{text[0, 12]}…#{text[-12, 12]}"
      end

      def recaptcha_submit_failed?
        return false unless on_signin?

        return true if recaptcha_page_message.present?

        source = @driver.page_source.to_s
        return true if RECAPTCHA_FAIL_HINTS.any? { |hint| source.include?(hint) }

        errors = Array(visible_form_errors)
        return true if errors.any? { |error| recaptcha_error_text?(error) }
        # Non-recaptcha form errors are handled before this (form_invalid).
        return false if errors.any?

        # Still on sign-in with no form errors — unknown reject; retry as recaptcha.
        true
      rescue
        on_signin?
      end

      def non_recaptcha_form_errors?(errors = visible_form_errors)
        list = Array(errors).map(&:to_s).reject(&:blank?)
        return false if list.empty?
        return false if list.any? { |error| recaptcha_error_text?(error) }

        true
      end

      def recaptcha_error_text?(error)
        text = error.to_s
        return true if text.include?(RECAPTCHA_MARK)

        RECAPTCHA_FAIL_HINTS.any? { |hint| text.include?(hint) }
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

      def truncate_sitekey(sitekey)
        text = sitekey.to_s
        return text if text.length <= 16

        "#{text[0, 8]}…#{text[-4, 4]}"
      end

      def confirm_review_page
        url_before = @driver.current_url.to_s
        source = @driver.page_source.to_s
        return if thanks_page?(url_before, source)
        return unless url_before.include?("/order/entry") || url_before.include?("/order/confirm")

        selector = submit_button_by_text
        return if selector.blank?

        click selector, "confirm order"
        Selenium::WebDriver::Wait.new(timeout: 20).until do
          current = @driver.current_url.to_s
          current != url_before || thanks_page?(current, @driver.page_source.to_s)
        end
      rescue Selenium::WebDriver::Error::TimeoutError
        nil
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

      def find_response_by_data_input_name(data_input_name)
        @conversations
          .select { |conversation| conversation.data_input_name == data_input_name }
          .max_by { |conversation| conversation.id.to_i }
          &.value
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

      def detect_thanks
        step("detect_result", "完了を確認") do
          url = @driver.current_url.to_s
          source = @driver.page_source.to_s
          complete = thanks_page?(url, source)
          raise LexicaStop.new("thanks_unconfirmed", "完了ページを確認できませんでした") unless complete

          @lexica_order_id = extract_order_id(source, url)
        end
      end

      def thanks_page?(url, source)
        return true if url.match?(/complete|thanks|thankyou|finish/i)
        return true if S::THANKS_HINTS.any? { |css| element_present?(css) }
        return true if source.match?(/ご注文(?:が)?完了|注文を受け付けました|order.?complete/i)

        false
      end

      def extract_order_id(source, url)
        match = source.match(/注文(?:番号|ID)[^\dA-Z]{0,8}([A-Z0-9\-]{6,})/) || url.match(/order(?:_id|Id)?=([A-Z0-9\-]+)/i)
        match && match[1]
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

      def add_to_cart_href
        add_to_cart_href_for(@sku)
      end

      def add_to_cart_href_for(sku)
        "#{cart_base_url}/Service/AddItemToCart/#{sku}/1"
      end

      def cart_base_url
        return @cart_url.sub(%r{/+\z}, "") if @cart_url.present?
        uri = URI.parse(@product_url) rescue nil
        return "#{uri.scheme}://#{uri.host}" if uri&.host&.include?("cart")

        "https://cart.mirai-japan.co.jp"
      end

      def signup_url
        "#{cart_base_url}/signup"
      end

      MAX_STEP_ACTIONS = 80
      MAX_ACTION_VALUE_LEN = 500
      MAX_ACTION_PAYLOAD_LEN = 4000

      def step(name, description)
        @current_step_actions = []
        @selenium_result&.update!(last_step_description: description, last_step_no: @step)
        yield
        log_step(name, description, ok: true)
      rescue LexicaStop
        log_step(name, description, ok: false, error: $!.message)
        raise
      rescue => e
        log_step(name, description, ok: false, error: e.message)
        raise
      end

      def log_step(name, description, ok: nil, error: nil)
        actions = Array(@current_step_actions)
        @current_step_actions = nil
        @selenium_result&.append_rpa_step(
          "name" => name,
          "description" => description,
          "url" => (@driver.current_url rescue nil),
          "ok" => ok,
          "error" => (error.nil? ? nil : sanitize_error(error)),
          "at" => Time.current.iso8601,
          "actions" => actions
        )
        @selenium_result&.update!(last_step_description: description, last_step_no: @step)
      end

      def record_action(type:, where:, label: nil, value: nil, request: nil, response: nil)
        return unless @current_step_actions.is_a?(Array)
        return if @current_step_actions.length >= MAX_STEP_ACTIONS

        entry = {
          "type" => type.to_s,
          "where" => where.to_s.slice(0, MAX_ACTION_VALUE_LEN),
          "label" => label.to_s
        }
        entry["value"] = redact_action_value(label, value) unless value.nil?
        entry["request"] = sanitize_action_payload(request) unless request.nil?
        entry["response"] = sanitize_action_payload(response) unless response.nil?
        @current_step_actions << entry
      end

      def sanitize_action_payload(payload)
        cleaned =
          case payload
          when Hash
            payload.each_with_object({}) do |(key, value), out|
              name = key.to_s
              next if name == "key"

              out[name] = sanitize_action_payload(value)
            end
          when Array
            payload.map { |item| sanitize_action_payload(item) }
          else
            sanitize_error(payload.to_s)
          end

        json = cleaned.is_a?(String) ? cleaned : JSON.generate(cleaned)
        return cleaned if json.bytesize <= MAX_ACTION_PAYLOAD_LEN

        truncated = json.byteslice(0, MAX_ACTION_PAYLOAD_LEN)
        { "truncated" => true, "preview" => truncated }
      rescue StandardError
        sanitize_error(payload.to_s).to_s.slice(0, MAX_ACTION_VALUE_LEN)
      end

      def redact_action_value(label, value)
        text = value.to_s
        return "********" if label.to_s.downcase.include?("password")
        return "[token]" if label.to_s.downcase.include?("token")

        sanitize_error(text).to_s.slice(0, MAX_ACTION_VALUE_LEN)
      end

      def mark_done
        Order.create!(
          client_id: @selenium_result.client_id,
          scenario_id: @scenario.id,
          user_input_id: @user_input_id,
          bot_type: :web
        )
        @selenium_result.update!(
          result: :done,
          end_time: DateTime.now,
          last_step_no: @step,
          last_step_description: "完了を確認",
          lexica_order_id: @lexica_order_id
        )
        @is_error = false
      end

      def fail_result(kind, message)
        @is_error = true
        @selenium_result&.update!(
          result: :error,
          end_time: DateTime.now,
          last_step_no: @step,
          last_step_description: @selenium_result.last_step_description,
          error_kind: kind,
          error_message: sanitize_error(message),
          screenshot_path: failure_screenshot_key
        )
        notify_failure(kind, message)
      end

      def failure_screenshot_key
        return if @selenium_result&.id.blank? || @selenium_result.client_id.blank?

        FileUtils.mkdir_p(@screenshot_path)
        path = File.join(@screenshot_path, "#{@scenario.id}_#{@user_input_id}_fail.png")
        write_png(path)
        AmazonWebServices::RpaScreenshotS3.call(
          path,
          client_id: @selenium_result.client_id,
          scenario_id: @scenario.id,
          bot_order_id: @selenium_result.id
        )
      rescue => error
        Log.error "RpaScreenshotS3 failed: #{error.message}"
        nil
      ensure
        delete_local_png(path)
      end

      def delete_local_png(path)
        return if path.blank? || !File.file?(path)

        File.delete(path)
      rescue
        nil
      end

      def notify_failure(kind, message)
        client = @scenario.chatbot&.user&.client
        email = client&.email.presence || @scenario.chatbot&.user&.email
        return if email.blank?

        OrderFailedMailer.send_email(
          email,
          email,
          {
            shop_name: client&.name,
            user_email: @user_email,
            path: @path,
            error_kind: kind,
            error_message: sanitize_error(message),
            user_input_id: @user_input_id
          }
        ).deliver_later
      rescue => e
        Log.error "OrderFailedMailer failed: #{e.message}"
      end

      def sanitize_error(message)
        text = message.to_s
        text = text.gsub(@password_value, "********") if @password_value.present?
        text = text.gsub(@token_key, "[token]") if @token_key.present?
        text.slice(0, 2000)
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

      def decode_card(raw)
        return {} if raw.blank?

        parsed = parse_json_value(raw)
        return parsed if parsed["token_key"].present? || parsed[:token_key].present?

        decoded = JWT.decode(raw, SECRET_KEY)[0]["data"]
        decoded.is_a?(String) ? parse_json_value(decoded) : decoded
      rescue
        parse_json_value(raw)
      end

      def decode_secret(raw)
        return nil if raw.blank?

        JWT.decode(raw, SECRET_KEY)[0]["data"]
      rescue
        raw
      end

      def normalize_payment(raw)
        value = raw.to_s
        return "credit" if value.match?(/credit|zeus|カード/i)
        return "gmo_atobarai" if value.match?(/gmo|後払/i)
        return "cod" if value.match?(/cod|代引|引換/i)

        raise LexicaStop.new("unknown_payment", "支払い方法が不正です: #{value.inspect}")
      end

      def masked_pan_from_card
        @card_data && (@card_data["masked_pan"] || @card_data["maskedPan"] || @card_data["mask"])
      end

      def card_expiry_from_card
        @card_data && (@card_data["expiry"] || @card_data["expire"])
      end

      def card_holder_from_card
        @card_data && (@card_data["holder"] || @card_data["cardholder"] || @card_data["name"])
      end
    end
  end
end
