module SeleniumServices
  module Lexica
    module StepLogging
      private

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
        # Prefer remembered URL when the driver socket is already dead (ReadTimeout).
        step_url =
          begin
            remember_driver_url!
          rescue StandardError
            @last_known_url.to_s
          end
        redacted_url = begin
          redact_step_url(step_url.presence || @last_known_url)
        rescue StandardError
          nil
        end
        on_complete =
          CompleteOrderSalvage.complete_url?(redacted_url) ||
          CompleteOrderSalvage.complete_url?(@last_known_url)
        if on_complete && redacted_url.present?
          @last_known_url = redacted_url
        end

        step_payload = {
          "name" => name,
          "description" => description,
          "url" => redacted_url,
          "ok" => ok,
          "error" => (error.nil? ? nil : sanitize_error(error)),
          "at" => Time.current.iso8601,
          "actions" => actions
        }

        # Persist complete URL before capture — CDP after a dead socket can hang.
        if on_complete
          @selenium_result&.append_rpa_step(step_payload)
          begin
            attach_step_screenshot!(step_payload)
            sync_last_step_screenshot!(step_payload)
          rescue StandardError => capture_error
            Log.error "complete-step capture skipped: #{capture_error.message}", @log_tab_level
          end
        else
          attach_step_screenshot!(step_payload)
          @selenium_result&.append_rpa_step(step_payload)
        end
        @selenium_result&.update!(last_step_description: description, last_step_no: @step)
      end


      def attach_step_screenshot!(step_payload)
        path = nil
        capture
        path = File.join(@screenshot_path, "#{@scenario.id}_#{@user_input_id}_#{@step}.png")
        return unless File.file?(path) && @selenium_result&.id.present? && @selenium_result.client_id.present?

        key = @selenium_result.upload_step_screenshot(
          path,
          scenario_id: @scenario.id,
          step_no: @step
        )
        return if key.blank?

        step_payload["screenshot_path"] = key
        step_payload["step_no"] = @step
      rescue StandardError => e
        Log.error "step screenshot upload failed: #{e.message}", @log_tab_level
      ensure
        delete_local_png(path)
      end


      def sync_last_step_screenshot!(step_payload)
        key = step_payload["screenshot_path"]
        return if key.blank? || !@selenium_result.respond_to?(:rpa_steps_array)

        steps = @selenium_result.rpa_steps_array
        return if steps.empty?

        last = steps.last
        return unless last.is_a?(Hash)

        last["screenshot_path"] = key
        last["step_no"] = step_payload["step_no"] if step_payload["step_no"]
        @selenium_result.update!(rpa_steps: JSON.generate(steps))
      rescue StandardError => e
        Log.error "sync_last_step_screenshot! failed: #{e.message}", @log_tab_level
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


      def mark_order_submitted!
        return if @order_submitted_marked

        @order_submitted_marked = true
        @selenium_result&.mark_submitted!
      end


      def sanitize_error(message)
        text = message.to_s
        text = text.gsub(@password_value, "********") if @password_value.present?
        text = text.gsub(@token_key, "[token]") if @token_key.present?
        text.slice(0, 2000)
      end


      def redact_step_url(url)
        text = url.to_s
        text = text.gsub(@token_key, "[token]") if @token_key.present?
        text.gsub(/token_key=(?!\[token\])[^&\s]+/, "token_key=[token]")
      end


    end
  end
end
