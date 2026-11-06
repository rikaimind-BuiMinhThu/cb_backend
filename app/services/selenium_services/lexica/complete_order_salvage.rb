module SeleniumServices
  module Lexica
    # Shared extractor for Lexica thank-you URLs. Used by Checkout, sinks, and LexicaScenarioJob.
    module CompleteOrderSalvage
      COMPLETE_PATH = %r{/order/complete/([A-Za-z0-9\-]+)}i.freeze

      module_function

      def complete_url?(url)
        url.to_s.match?(COMPLETE_PATH)
      end

      def code_from_url(url)
        url.to_s[COMPLETE_PATH, 1].presence
      end

      def code_from_steps(steps)
        Array(steps).reverse_each do |step|
          next unless step.is_a?(Hash)

          code = code_from_url(step["url"] || step[:url])
          return code if code.present?
        end
        nil
      end

      def extract_order_id(source, url)
        from_complete = code_from_url(url)
        return from_complete if from_complete.present?

        text = source.to_s
        href = url.to_s
        match =
          text.match(/注文(?:番号|ID)[^\dA-Za-z]{0,8}([A-Za-z0-9\-]{6,})/) ||
          href.match(/order(?:_id|Id)?=([A-Za-z0-9\-]+)/i)
        match && match[1]
      end

      def promote_record!(record, lexica_order_id:, last_step_no: nil, last_step_description: "完了を確認")
        return false if record.blank?
        return true if record.done? && record.lexica_order_id.present?

        code = lexica_order_id.presence || code_from_steps(record.rpa_steps_array)
        return false if code.blank?

        SeleniumServices::Lexica::ActiveRecordResultSink.new(record).mark_done!(
          lexica_order_id: code,
          last_step_no: last_step_no || record.last_step_no,
          last_step_description: last_step_description
        )
        true
      rescue StandardError => e
        Rails.logger.error("CompleteOrderSalvage.promote_record! failed: #{e.message}")
        false
      end
    end
  end
end
