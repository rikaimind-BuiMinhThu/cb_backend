module Lexica
  class RpaEvents
    UPDATE_KEYS = %w[
      path payment sku product_url cart_url masked_pan card_expiry card_holder
      resolved_sku resolved_product_url offer_surfaces last_step_description last_step_no
      token_key
    ].freeze

    def self.apply(result, params)
      new(result, params).apply
    end

    def self.requeue_if_retryable(result)
      return unless Lexica::RpaQueue.lambda_runtime?
      return if result.order_submitted_at.present?
      return if result.rpa_attempt.to_i >= Lexica::RpaClaim::MAX_ATTEMPTS
      return if result.submitted_to_cart?
      return unless result.error?

      Lexica::RpaQueue.enqueue(result.id)
    end

    def initialize(result, params)
      @result = result
      @params = params.respond_to?(:with_indifferent_access) ? params.with_indifferent_access : params
    end

    def apply
      case @params[:event].to_s
      when "update" then update_attrs
      when "append_step" then append_step
      when "patch_last_step" then patch_last_step
      when "submitted" then mark_submitted
      when "done" then mark_done
      when "fail" then mark_failed
      else
        { ok: false, error: "unknown_event" }
      end
    end

    private

    def update_attrs
      attrs = @params[:attrs]
      attrs = {} unless attrs.respond_to?(:to_h)
      filtered = attrs.to_h.stringify_keys.slice(*UPDATE_KEYS)
      @result.update!(filtered) if filtered.any?
      { ok: true }
    end

    def append_step
      step = @params[:step]
      return { ok: false, error: "missing_step" } unless step.respond_to?(:to_h)

      @result.append_rpa_step(step.to_h.stringify_keys)
      { ok: true }
    end

    def patch_last_step
      steps = @result.rpa_steps_array
      return { ok: false, error: "no_steps" } if steps.empty?

      last = steps.last
      return { ok: false, error: "bad_last_step" } unless last.is_a?(Hash)

      key = @params[:screenshot_path].to_s
      return { ok: false, error: "missing_screenshot_path" } if key.blank?

      last["screenshot_path"] = key
      last["step_no"] = @params[:step_no] if @params[:step_no].present?
      @result.update!(rpa_steps: JSON.generate(steps))
      { ok: true }
    end

    def mark_submitted
      @result.update!(order_submitted_at: Time.current) if @result.order_submitted_at.blank?
      { ok: true }
    end

    def mark_done
      return { ok: true, duplicate: true } if @result.done?

      ensure_order_row!
      @result.update!(
        result: :done,
        end_time: Time.current,
        last_step_no: @params[:last_step_no],
        last_step_description: @params[:last_step_description].presence || "完了を確認",
        lexica_order_id: @params[:lexica_order_id],
        error_kind: nil,
        error_message: nil
      )
      { ok: true }
    end

    def mark_failed
      return { ok: true, duplicate: true } if @result.done?

      # Lambda may post fail after a dead-socket timeout even when /order/complete is in steps.
      complete_code = SeleniumServices::Lexica::CompleteOrderSalvage.code_from_steps(@result.rpa_steps_array)
      if complete_code.present?
        return mark_done_with_id(complete_code)
      end

      @result.update!(
        result: :error,
        end_time: Time.current,
        last_step_no: @params[:last_step_no],
        last_step_description: @params[:last_step_description],
        error_kind: @params[:error_kind],
        error_message: @params[:error_message].to_s.slice(0, 2000),
        screenshot_path: @params[:screenshot_path]
      )
      Lexica::FailureMail.deliver(@result, @params[:error_kind], @params[:error_message])
      self.class.requeue_if_retryable(@result)
      { ok: true }
    end

    def mark_done_with_id(lexica_order_id)
      @params = @params.merge(
        lexica_order_id: lexica_order_id,
        last_step_description: @params[:last_step_description].presence || "完了を確認"
      )
      mark_done
    end

    def ensure_order_row!
      return if Order.exists?(
        client_id: @result.client_id,
        scenario_id: @result.scenario_id,
        user_input_id: @result.user_input_id
      )

      Order.create!(
        client_id: @result.client_id,
        scenario_id: @result.scenario_id,
        user_input_id: @result.user_input_id,
        bot_type: :web
      )
    end
  end
end
