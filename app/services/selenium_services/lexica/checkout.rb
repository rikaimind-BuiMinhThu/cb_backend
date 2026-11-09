require "selenium-webdriver"
require "base64"
require "json"
require "uri"
require "net/http"
require File.dirname(__FILE__) + "/../../log"

module SeleniumServices
  module Lexica
    # Module-level so StepLogging / CartFlow / Recaptcha rescue LexicaStop without
    # nesting under Checkout (Zeitwerk + include constant lookup).
    class LexicaStop < StandardError
      attr_reader :error_kind

      def initialize(error_kind, message)
        @error_kind = error_kind
        super(message)
      end
    end

    # Alias for Selectors so included mixins (CartFlow, DomActions, …) resolve S::
    # via Lexica nesting — Checkout::S is not visible from those modules.
    S = Selectors

    class Checkout < SeleniumServices::Lexica::Base
      S = Selectors
      PATH_NAME = nil

      include StepLogging
      include DomActions
      include CartFlow
      include PaymentDelivery
      include Recaptcha
      include CompleteOrder

      def process
        @log_tab_level += 1
        Log.info "Start lexica #{self.class.name}", @log_tab_level
        snapshot_scenario_urls
        run_checkout_flow
      end

      def run_checkout_flow
        apply_selected_upsell_and_cross_sell
        run_checkout
        mark_done
      rescue OfferError, LexicaStop => error
        mark_done_or_fail(error.error_kind, error.message)
      rescue StandardError => error
        Log.error error.message
        Log.error error.backtrace.join("\n\t")
        mark_done_or_fail("rpa_error", error.message)
      ensure
        salvage_completed_order
        quit_driver
      end

      private

      def run_checkout
        raise NotImplementedError, "#{self.class} must implement run_checkout"
      end

      def mark_done_or_fail(error_kind, message)
        if recover_completed_order!
          mark_done
        else
          fail_result(error_kind, message)
        end
      end

      def salvage_completed_order
        return if @lexica_order_id.present?
        return unless recover_completed_order!

        mark_done
      rescue StandardError => error
        Log.error "salvage_completed_order failed: #{error.class}: #{error.message}"
      end

      def quit_driver
        quit
      rescue StandardError => error
        Log.error "quit_driver failed: #{error.class}: #{error.message}"
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
        @click_confirm_teiki = false
        @confirm_teiki_applied = false
        @token_key = @card_data && (@card_data["token_key"] || @card_data[:token_key])
      end

      def apply_selected_upsell_and_cross_sell
        resolved = OfferResolver.new(@scenario, @conversations).resolve!
        @sku = resolved.sku
        @product_url = resolved.product_url
        @cart_skus = resolved.cart_skus
        @offer_surfaces = resolved.surfaces.dup
        @cross_sell_sku = resolved.cross_sell_sku
        @click_confirm_teiki = resolved.click_confirm_teiki
        @confirm_teiki_applied = false
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

      def apply_payment_and_submit
        apply_payment
        apply_delivery
        submit_order
        detect_thanks
        apply_thanks_offers
      end

      # Runs on /order/confirm only (see confirm_review_page). Entry form is too early.
      def apply_confirm_upsell
        return unless @click_confirm_teiki

        # Chat selected upsell: never silently keep trial when the scenario flag is off.
        unless offer_flag?(:lexica_offer_confirm_upsell)
          raise LexicaStop.new(
            "confirm_upsell_disabled",
            "チャットでアップセル選択済みですが confirm upsell が無効です"
          )
        end

        step("confirm_upsell", "confirm_upsell") do
          matched = @driver.execute_script(<<~JS)
            var el = document.querySelector(#{S::CONFIRM_UPSELL.to_json});
            if (!el) return null;
            var oc = el.getAttribute('onclick') || '';
            var text = (el.innerText || el.value || '').replace(/\\s+/g, '');
            if (oc.indexOf('Upselling') === -1) return null;
            if (text.indexOf('定期') === -1) return null;
            return {
              id: el.id || '',
              className: String(el.className || '').slice(0, 200),
              text: text.slice(0, 80),
              onclick: oc.slice(0, 200)
            };
          JS
          unless matched
            raise LexicaStop.new("confirm_upsell_missing", "確認画面のアップセルが見つかりません")
          end

          record_action(
            type: :detect,
            where: S::CONFIRM_UPSELL,
            label: "confirm_teiki",
            value: matched.to_json
          )
          click S::CONFIRM_UPSELL, "confirm_upsell"
          wait_after_confirm_teiki!
          # Cart line stays trial SKU; Lexica Upselling swaps on their side.
          # Surfaces + teiki flag make ops reporting unambiguous.
          @confirm_teiki_applied = true
          record_offer_surface("confirm_upsell")
          snapshot_confirm_teiki!
        end
      end

      def wait_after_confirm_teiki!
        wait_page_load_complete
        Selenium::WebDriver::Wait.new(timeout: 15).until do
          url = @driver.current_url.to_s
          source = begin
            @driver.page_source.to_s
          rescue StandardError
            ""
          end
          url.include?("/order/confirm") || thanks_page?(url, source)
        end
        Selenium::WebDriver::Wait.new(timeout: 10).until do
          url = @driver.current_url.to_s
          source = begin
            @driver.page_source.to_s
          rescue StandardError
            ""
          end
          next true if thanks_page?(url, source)

          submit_button_by_text.present?
        end
      rescue Selenium::WebDriver::Error::TimeoutError
        nil
      end

      def snapshot_confirm_teiki!
        return unless @selenium_result

        attrs = {}
        # Cart SKU stays trial; offer_surfaces includes confirm_upsell for ops.
        if @selenium_result.respond_to?(:resolved_sku)
          attrs[:resolved_sku] = @sku.to_s
        end
        if @selenium_result.respond_to?(:offer_surfaces)
          attrs[:offer_surfaces] = JSON.generate(Array(@offer_surfaces))
        end
        @selenium_result.update!(attrs) if attrs.any?
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
    end
  end
end
