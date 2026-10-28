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

    def mark_submitted
      @result.update!(order_submitted_at: Time.current) if @result.order_submitted_at.blank?
      { ok: true }
    end

    def mark_done
      return { ok: true, duplicate: true } if @result.done?

      Order.create!(
        client_id: @result.client_id,
        scenario_id: @result.scenario_id,
        user_input_id: @result.user_input_id,
        bot_type: :web
      )
      @result.update!(
        result: :done,
        end_time: Time.current,
        last_step_no: @params[:last_step_no],
        last_step_description: @params[:last_step_description].presence || "完了を確認",
        lexica_order_id: @params[:lexica_order_id]
      )
      { ok: true }
    end

    def mark_failed
      return { ok: true, duplicate: true } if @result.done?

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
  end
end
