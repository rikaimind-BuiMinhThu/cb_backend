module SeleniumServices
  module Lexica
    module PaymentDelivery
      private

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

        begin
          Selenium::WebDriver::Wait.new(timeout: 10).until { page_contains?("カード番号") }
        rescue Selenium::WebDriver::Error::TimeoutError
          raise LexicaStop.new("missing_token", "カード番号のフォームが見つかりません")
        end

        month, year = card_expiry_parts
        result = @driver.execute_script(
          <<~JS,
          var token = arguments[0];
          var masked = arguments[1];
          var month = arguments[2];
          var year = arguments[3];
          var holder = arguments[4];
          var phone = arguments[5];
          (function tapOrderPost() {
            if (window.__ecchXhrTapped) return;
            window.__ecchXhrTapped = true;
            window.__ecchPosts = [];
            var open = XMLHttpRequest.prototype.open;
            var send = XMLHttpRequest.prototype.send;
            XMLHttpRequest.prototype.open = function(method, url) {
              this.__ecchUrl = String(url || '');
              this.__ecchMethod = String(method || '');
              return open.apply(this, arguments);
            };
            XMLHttpRequest.prototype.send = function(body) {
              var xhr = this;
              if (xhr.__ecchUrl.indexOf('/ps/op/') !== -1) {
                var fields = [];
                try {
                  String(body || '').split('&').forEach(function(pair) {
                    var kv = pair.split('=');
                    var key = decodeURIComponent(kv[0] || '');
                    var val = decodeURIComponent((kv[1] || '').replace(/\\+/g, ' '));
                    if (!key) return;
                    var shown = val;
                    if (/token|TOKEN|card|CARD|PASSWORD/i.test(key)) shown = val ? ('len' + val.length) : '';
                    fields.push(key + '=' + shown.slice(0, 40));
                  });
                } catch (e) {}
                xhr.addEventListener('loadend', function() {
                  window.__ecchPosts.push({
                    method: xhr.__ecchMethod,
                    url: xhr.__ecchUrl.slice(0, 200),
                    status: xhr.status,
                    response: String(xhr.responseText || '').slice(0, 3000),
                    fields: fields.slice(0, 60)
                  });
                });
              }
              return send.apply(this, arguments);
            };
          })();
          var telno = (function fillTelno() {
            var state = [];
            if (window.jQuery) {
              try { window.jQuery('input[name$="PHONE_NUMBER"]').trigger('change'); } catch (e) {}
            }
            Array.prototype.forEach.call(document.querySelectorAll('input[name="TELNO"]'), function(node) {
              if (node.value) { state.push('had'); return; }
              if (!phone) { state.push('empty'); return; }
              node.value = phone;
              state.push('set');
            });
            return state;
          })();
          var stubbed = (function installZeusStub() {
            var payload = {
              result: 1,
              status: 'success',
              token_key: token,
              masked_card_number: masked,
              card_expires_month: month,
              card_expires_year: year,
              card_name: holder
            };
            var stub = function() {
              var cb = null;
              var i;
              for (i = 0; i < arguments.length; i += 1) {
                if (typeof arguments[i] === 'function') cb = arguments[i];
              }
              if (cb) {
                try { cb(payload); } catch (e) {}
              }
              return payload;
            };
            var installed = [];
            window.__ecchZeusStub = stub;
            if (window.zeusToken && typeof window.zeusToken === 'object') {
              window.zeusToken.getToken = stub;
              installed.push('zeusToken');
            }
            if (window.zeusTokenClass && window.zeusTokenClass.prototype) {
              window.zeusTokenClass.prototype.getToken = stub;
              installed.push('zeusTokenClass');
            }
            if (window.ZeusToken && window.ZeusToken.prototype) {
              window.ZeusToken.prototype.getToken = stub;
              installed.push('ZeusToken');
            }
            return installed;
          })();
          var label = document.evaluate(
            "//*[contains(normalize-space(.), 'カード番号') and not(./*[contains(normalize-space(.), 'カード番号')])]",
            document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null
          ).singleNodeValue;
          var form = label && (label.closest('form') || label.closest('#order__payment') || label.parentElement);
          if (!form) return { ok: false, names: [] };
          form.setAttribute('data-ecch-card-form', '1');

          var invalid = [];
          Array.prototype.forEach.call(form.querySelectorAll('input, select, textarea'), function(control) {
            if (typeof control.checkValidity === 'function' && !control.checkValidity()) {
              invalid.push(control.name || control.id || control.type);
            }
          });
          var button = document.querySelector('[data-ecch-guest-submit="1"]');
          if (!button) {
            var nodes = document.querySelectorAll('button');
            var i;
            for (i = 0; i < nodes.length; i += 1) {
              var oc = nodes[i].getAttribute('onclick') || '';
              var text = (nodes[i].innerText || '').replace(/\\s+/g, '');
              if (text.indexOf('ご注文内容の確認へ') === -1) continue;
              if (oc.indexOf('flg-guest') === -1 || oc.indexOf('true') === -1) continue;
              button = nodes[i];
              break;
            }
          }
          var onclick = button ? String(button.getAttribute('onclick') || '').slice(0, 300) : '';

          var el = form.querySelector('input[name="token_key"], input[name="TOKEN_KEY"], input#token_key');
          if (!el) {
            el = document.createElement('input');
            el.type = 'hidden';
            el.name = 'token_key';
            form.appendChild(el);
          }
          el.value = token;
          el.dispatchEvent(new Event('input', { bubbles: true }));
          el.dispatchEvent(new Event('change', { bubbles: true }));

          var zeus = form.querySelector('input[name="zeus_token_value"]');
          if (!zeus) {
            zeus = document.createElement('input');
            zeus.type = 'hidden';
            zeus.name = 'zeus_token_value';
            form.appendChild(zeus);
          }
          zeus.disabled = false;
          zeus.value = token;
          zeus.dispatchEvent(new Event('input', { bubbles: true }));
          zeus.dispatchEvent(new Event('change', { bubbles: true }));

          var hints = ['カード番号', '有効期限', 'カード名義'];
          function nearText(control) {
            var bits = [];
            var node = control;
            var depth;
            for (depth = 0; depth < 4 && node; depth += 1) {
              var prev = node.previousElementSibling;
              if (prev) bits.push(prev.textContent || '');
              var parent = node.parentElement;
              if (parent) {
                Array.prototype.forEach.call(parent.childNodes, function(child) {
                  if (child.nodeType === 3) bits.push(child.textContent || '');
                });
              }
              node = parent;
            }
            return bits.join(' ').replace(/\\s+/g, '');
          }
          function blank(control) {
            var value = (control.value || '').trim();
            return value === '' || value === '--' || value === '-';
          }
          Array.prototype.forEach.call(form.querySelectorAll('input, select, textarea'), function(control) {
            if (control === el) return;
            if (!blank(control)) return;
            var around = nearText(control);
            var hit = hints.some(function(hint) { return around.indexOf(hint) !== -1; });
            if (!hit) return;
            control.required = false;
            control.removeAttribute('required');
            control.removeAttribute('aria-required');
          });

          var cardNames = ['zeus_token_card_number', 'zeus_token_card_expires_month', 'zeus_token_card_expires_year', 'zeus_token_card_name'];
          var disabled = [];
          cardNames.forEach(function(name) {
            Array.prototype.forEach.call(form.querySelectorAll('[name="' + name + '"]'), function(control) {
              if (!blank(control)) return;
              control.required = false;
              control.removeAttribute('required');
              control.removeAttribute('aria-required');
              control.disabled = true;
              disabled.push(name);
            });
          });

          function setNamed(name, value) {
            if (!value) return false;
            var node = form.querySelector('[name="' + name + '"]');
            if (!node) return false;
            node.disabled = false;
            node.value = value;
            return true;
          }
          var filled = [];
          if (setNamed('zeus_token_masked_card_no', masked)) filled.push('zeus_token_masked_card_no');
          if (setNamed('zeus_token_return_card_expires_month', month)) filled.push('zeus_token_return_card_expires_month');
          if (setNamed('zeus_token_return_card_expires_year', year)) filled.push('zeus_token_return_card_expires_year');
          if (setNamed('zeus_token_return_card_name', holder)) filled.push('zeus_token_return_card_name');

          form.noValidate = true;
          form.checkValidity = function() { return true; };
          form.reportValidity = function() { return true; };

          var names = Array.prototype.map.call(form.querySelectorAll('input, select, textarea'), function(control) {
            return control.name || control.id || control.type;
          }).filter(Boolean);
          return {
            ok: !!(el.value && zeus.value),
            names: names.slice(0, 40),
            disabled: disabled,
            filled: filled,
            onclick: onclick,
            invalid: invalid.slice(0, 40),
            stubbed: stubbed,
            telno: telno
          };
        JS
          @token_key.to_s,
          masked_pan_from_card.to_s,
          month,
          year,
          card_holder_from_card.to_s,
          @phone_number.to_s.gsub(/\D/, "")
        )

        names = Array(result.is_a?(Hash) ? (result["names"] || result[:names]) : nil)
        disabled = Array(result.is_a?(Hash) ? (result["disabled"] || result[:disabled]) : nil)
        filled = Array(result.is_a?(Hash) ? (result["filled"] || result[:filled]) : nil)
        invalid = Array(result.is_a?(Hash) ? (result["invalid"] || result[:invalid]) : nil)
        onclick = (result.is_a?(Hash) ? (result["onclick"] || result[:onclick]) : nil).to_s.slice(0, 300)
        stubbed = Array(result.is_a?(Hash) ? (result["stubbed"] || result[:stubbed]) : nil)
        telno = Array(result.is_a?(Hash) ? (result["telno"] || result[:telno]) : nil)
        record_action(
          type: "fill",
          where: "form:カード番号",
          label: "token_key",
          value: "[token]",
          request: {
            "inputs" => names,
            "zeus_token_value" => "set",
            "disabled" => disabled,
            "return_fields" => filled,
            "onclick" => onclick,
            "invalid" => invalid,
            "getToken_stub" => stubbed,
            "telno" => telno
          }
        )
        return if result.is_a?(Hash) && (result["ok"] || result[:ok])

        raise LexicaStop.new("missing_token", "カード番号のフォームにトークンを置けませんでした")
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
            begin
              if @payment_method == "credit"
                inject_token_key
                mark_order_submitted!
                submit_guest_onsubmit
              else
                mark_order_submitted!
                click selector, "submit order"
              end
              remember_driver_url!
              wait_for_checkout_progress
              remember_driver_url!
              record_order_posts if @payment_method == "credit"
              if on_signin?
                errors = Array(visible_form_errors)
                errors = [@card_alert_text] if errors.empty? && @card_alert_text.present?
                raise LexicaStop.new("form_invalid", errors.presence&.join(" / ") || "確認画面へ進めませんでした")
              end
              confirm_review_page
              remember_driver_url!
            rescue Net::ReadTimeout, Errno::ECONNREFUSED, Selenium::WebDriver::Error::WebDriverError => e
              # page_source/wait can time out after Lexica already redirected to /order/complete/.
              remember_driver_url!
              raise unless recover_completed_order!

              Log.info "submit_order recovered after #{e.class}: order=#{@lexica_order_id}", @log_tab_level
            end
          end
        end
      end


      def wait_for_checkout_progress
        Selenium::WebDriver::Wait.new(timeout: 45).until do
          !on_signin? || visible_form_errors.any? || recaptcha_page_message.present? || recaptcha_token_present?
        end
      rescue Selenium::WebDriver::Error::TimeoutError
        nil
      rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError
        accept_card_alert
        nil
      end


      def submit_guest_onsubmit
        return false if @card_form_submitted

        @card_form_submitted = true
        result = @driver.execute_script(<<~JS)
          var button = document.querySelector('[data-ecch-guest-submit="1"]');
          if (!button) return { called: 'missing' };
          var form = button.form || button.closest('form');
          var guest = document.querySelector('#flg-guest');
          if (guest) guest.value = 'true';
          if (form) form.noValidate = true;
          if (typeof button.onclick === 'function') {
            button.onclick.call(button, new MouseEvent('click', { bubbles: true, cancelable: true }));
            return { called: 'onclick', form: !!form, onsubmit: !!(form && typeof form.onsubmit === 'function') };
          }
          button.click();
          return { called: 'click', form: !!form, onsubmit: !!(form && typeof form.onsubmit === 'function') };
        JS
        called = result.is_a?(Hash) ? (result["called"] || result[:called]).to_s : "missing"
        record_action(
          type: "submit",
          where: "form:カード番号",
          label: "onsubmit",
          value: called,
          request: { "form" => (result.is_a?(Hash) ? result["form"] : nil), "onsubmit" => (result.is_a?(Hash) ? result["onsubmit"] : nil) }
        )
        accept_card_alert
        called != "missing"
      rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError
        accept_card_alert
        true
      rescue StandardError => error
        record_action(type: "submit", where: "form:カード番号", label: "onsubmit", value: "error")
        Log.error "guest onsubmit failed: #{sanitize_error(error.message)}", @log_tab_level
        accept_card_alert
        true
      end


      def record_order_posts
        posts = @driver.execute_script("return window.__ecchPosts || [];")
        Array(posts).last(3).each do |post|
          next unless post.is_a?(Hash)

          record_action(
            type: "detect",
            where: post["url"].to_s,
            label: "order_post",
            value: "#{post["method"]} #{post["status"]}",
            request: { "fields" => post["fields"] },
            response: post["response"].to_s
          )
        end
      rescue StandardError => error
        Log.error "order post capture failed: #{sanitize_error(error.message)}", @log_tab_level
      end


      def accept_card_alert
        alert = @driver.switch_to.alert
        text = alert.text.to_s
        alert.accept
        record_action(type: "detect", where: "alert", label: "card_alert", value: sanitize_error(text).slice(0, 300))
        @card_alert_text = text
        text
      rescue Selenium::WebDriver::Error::NoSuchAlertError
        nil
      rescue StandardError
        nil
      end


      def normalize_payment(raw)
        value = raw.to_s
        return "credit" if value.match?(/credit|zeus|カード/i)
        return "gmo_atobarai" if value.match?(/gmo|後払/i)
        return "cod" if value.match?(/cod|代引|引換/i)

        raise LexicaStop.new("unknown_payment", "支払い方法が不正です: #{value.inspect}")
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


      def card_expiry_parts
        digits = card_expiry_from_card.to_s.gsub(/\D/, "")
        return ["", ""] if digits.length < 4

        [digits[0, 2], "20#{digits[-2, 2]}"]
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
