module SeleniumServices
  module Lexica
    module CompleteOrder
      private

            def detect_thanks
        step("detect_result", "完了を確認") do
          url = remember_driver_url!
          if CompleteOrderSalvage.complete_url?(url)
            @lexica_order_id = CompleteOrderSalvage.code_from_url(url)
            next
          end

          source = begin
            @driver.page_source.to_s
          rescue StandardError
            ""
          end
          complete = thanks_page?(url, source)
          unless complete
            banner = purchase_blocked_banner
            raise LexicaStop.new("purchase_blocked", banner) if banner.present?

            raise LexicaStop.new("thanks_unconfirmed", "完了ページを確認できませんでした")
          end

          @lexica_order_id =
            extract_order_id(source, url).presence ||
            extract_order_id("", url).presence ||
            extract_order_id("", @last_known_url.to_s)
        end
      end


      def purchase_blocked_banner
        visible = Array(visible_form_errors).map { |text| text.to_s.gsub(/\s+/, " ").strip }
        hit = visible.find { |text| purchase_blocked_text?(text) }
        return hit if hit.present?

        source = @driver.page_source.to_s.gsub(/\s+/, " ")
        match = source.match(/[^。]{0,80}(?:配送条件|購入いただけません)[^。]{0,80}。?/)
        match && match[0].strip.presence
      end


      def purchase_blocked_text?(text)
        value = text.to_s
        value.include?("配送条件") || value.include?("購入いただけません")
      end


      def thanks_page?(url, source)
        return true if url.match?(/complete|thanks|thankyou|finish/i)
        return true if S::THANKS_HINTS.any? { |css| element_present?(css) }
        return true if source.match?(/ご注文(?:が)?完了|注文を受け付けました|order.?complete/i)

        false
      end


      def extract_order_id(source, url)
        CompleteOrderSalvage.extract_order_id(source, url)
      end

      # Lexica can land on /order/complete/{code} while Selenium HTTP times out reading the page.
      # Treat that URL as success so we do not mark a real Lexica order as rpa_error.
      # Do not call the dead driver first — current_url can hang on Net::ReadTimeout.

      def recover_completed_order!
        # Steps / @last_known_url only — never touch the driver here (dead socket hangs).
        url = completed_order_url_from_memory
        return false if url.blank?

        @lexica_order_id = extract_order_id("", url).presence || @lexica_order_id
        record_offer_surface("recovered_after_complete_timeout")
        Log.info "Recovered Lexica complete URL #{url} order=#{@lexica_order_id}", @log_tab_level
        true
      rescue StandardError => e
        Log.error "recover_completed_order! failed: #{e.message}"
        false
      end


      def completed_order_url_from_memory
        [
          last_recorded_complete_url,
          @last_known_url.to_s,
        ].find { |candidate| CompleteOrderSalvage.complete_url?(candidate) }.to_s
      end


      def remember_driver_url!
        url = @driver.current_url.to_s
        @last_known_url = url if url.present?
        url
      rescue StandardError
        @last_known_url.to_s
      end


      def last_recorded_complete_url
        sink = @selenium_result
        return "" if sink.blank?

        sink.reload if sink.respond_to?(:reload)
        steps =
          if sink.respond_to?(:rpa_steps_array)
            sink.rpa_steps_array
          else
            []
          end
        return "" unless steps.is_a?(Array)

        hit = steps.reverse.find do |step|
          next false unless step.is_a?(Hash)

          CompleteOrderSalvage.complete_url?(step["url"] || step[:url])
        end
        hit && (hit["url"] || hit[:url]).to_s
      rescue StandardError
        ""
      end


      def mark_done
        if @lexica_order_id.blank?
          @lexica_order_id =
            extract_order_id("", @last_known_url.to_s).presence ||
            extract_order_id("", last_recorded_complete_url).presence
        end
        @selenium_result&.mark_done!(
          lexica_order_id: @lexica_order_id,
          last_step_no: @step,
          last_step_description: "完了を確認"
        )
        @is_error = false
      end


      def fail_result(kind, message)
        # Salvage before any screenshot — CDP on a dead socket can delay mark_failed!
        # past Sidekiq death and leave a real /order/complete as rpa_error.
        if recover_completed_order!
          mark_done
          return
        end

        @is_error = true
        screenshot = begin
          failure_screenshot_key
        rescue StandardError
          nil
        end
        @selenium_result&.mark_failed!(
          kind: kind,
          message: sanitize_error(message),
          last_step_no: @step,
          last_step_description: @selenium_result&.last_step_description,
          screenshot_path: screenshot
        )
      end


      def failure_screenshot_key
        return if @selenium_result&.id.blank? || @selenium_result.client_id.blank?

        FileUtils.mkdir_p(@screenshot_path)
        path = File.join(@screenshot_path, "#{@scenario.id}_#{@user_input_id}_fail.png")
        write_png(path)
        @selenium_result.upload_failure_screenshot(path, scenario_id: @scenario.id)
      rescue => error
        Log.error "failure screenshot failed: #{error.message}"
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


      # Guest submit may land on /order/entry first, then /order/confirm.
      # Upsell (定期 / #selectItem) must run on confirm even after that hop.
      CONFIRM_REVIEW_MAX_PASSES = 2

      def confirm_review_page
        CONFIRM_REVIEW_MAX_PASSES.times do |pass|
          url = @driver.current_url.to_s
          source = @driver.page_source.to_s
          return if thanks_page?(url, source)
          return unless url.include?("/order/entry") || url.include?("/order/confirm")

          if url.include?("/order/confirm")
            # Teiki first: blocked banner may clear after Upselling swaps the cart line.
            apply_confirm_upsell
            banner = purchase_blocked_banner
            if banner.present?
              raise LexicaStop.new("purchase_blocked", banner)
            end
          end

          selector = submit_button_by_text
          return if selector.blank?

          url_before = url
          click selector, "confirm order"
          Selenium::WebDriver::Wait.new(timeout: 20).until do
            current = @driver.current_url.to_s
            current != url_before || thanks_page?(current, @driver.page_source.to_s)
          end

          current = @driver.current_url.to_s
          return if thanks_page?(current, @driver.page_source.to_s)
          # Entry → confirm: one more pass for teiki + final 注文を確定.
          break unless pass.zero? && current.include?("/order/confirm")
        end
      rescue Selenium::WebDriver::Error::TimeoutError
        nil
      end


    end
  end
end
