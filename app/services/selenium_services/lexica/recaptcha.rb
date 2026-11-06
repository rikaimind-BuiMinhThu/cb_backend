require File.dirname(__FILE__) + "/../../captcha/two_captcha"

module SeleniumServices
  module Lexica
    module Recaptcha
      RECAPTCHA_MARK = "リキャプチャ".freeze
      RECAPTCHA_SOLVE_MAX_ATTEMPTS = 5
      RECAPTCHA_FAIL_HINTS = [
        RECAPTCHA_MARK,
        "Fail to verify ReCaptcha",
        "Fail to verify Recaptcha",
        "fail to verify recaptcha",
      ].freeze

      private

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
              # Lexica may mutate fields between inject and click; re-bind immediately before submit.
              inject_recaptcha_token(result[:token])
              inject_token_key if @payment_method == "credit"
              mark_order_submitted!
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
          var g = window.grecaptcha;
          if (!g) {
            window.grecaptcha = {
              ready: function(cb) { if (typeof cb === 'function') { cb(); } },
              execute: function() { return Promise.resolve(t); }
            };
          } else {
            g.execute = function() { return Promise.resolve(t); };
          }

          // Prefer the guest/signup form Lexica posts; avoid document-wide duplicates.
          var form = document.querySelector('.form-order-signup') ||
            document.querySelector('#signup-form') ||
            document.querySelector('form') ||
            document.body;

          function setNamed(name, createIfMissing) {
            var els = form.querySelectorAll('[name=\"' + name + '\"]');
            if (!els.length && createIfMissing) {
              var el = document.createElement(name === 'g-recaptcha-response' ? 'textarea' : 'input');
              if (name !== 'g-recaptcha-response') el.type = 'hidden';
              el.name = name;
              if (name === 'g-recaptcha-response') el.id = 'g-recaptcha-response';
              form.appendChild(el);
              els = form.querySelectorAll('[name=\"' + name + '\"]');
            }
            Array.prototype.forEach.call(els, function(el) {
              el.value = t;
              if (el.innerHTML !== undefined && name === 'g-recaptcha-response') el.innerHTML = t;
              try {
                el.dispatchEvent(new Event('input', { bubbles: true }));
                el.dispatchEvent(new Event('change', { bubbles: true }));
              } catch (e) {}
            });
            return els.length;
          }

          // Lexica submits RECAPTCHA_TOKEN. Only create that if missing; never invent g-recaptcha-response.
          setNamed('RECAPTCHA_TOKEN', true);
          setNamed('g-recaptcha-response', false);
          // Widget textarea often sits outside the signup form; fill existing nodes only.
          Array.prototype.forEach.call(document.querySelectorAll('[name=\"g-recaptcha-response\"]'), function(el) {
            el.value = t;
            if (el.innerHTML !== undefined) el.innerHTML = t;
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
            "egress_ip" => selenium_egress_ip,
            "fields" => recaptcha_field_snapshot
          }
        )
      end


      def selenium_egress_ip
        return @selenium_egress_ip if defined?(@selenium_egress_ip)

        # STG Chrome shares the Sidekiq host egress; no in-app proxy exists for 2Captcha.
        uri = URI("https://api.ipify.org")
        res = Net::HTTP.get_response(uri)
        @selenium_egress_ip = res.is_a?(Net::HTTPSuccess) ? res.body.to_s.strip.presence : nil
      rescue StandardError
        @selenium_egress_ip = nil
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


      def truncate_sitekey(sitekey)
        text = sitekey.to_s
        return text if text.length <= 16

        "#{text[0, 8]}…#{text[-4, 4]}"
      end


    end
  end
end
