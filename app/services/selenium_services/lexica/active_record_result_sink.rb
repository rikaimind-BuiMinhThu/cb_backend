module SeleniumServices
  module Lexica
    class ActiveRecordResultSink
      TRACKED = %i[resolved_sku resolved_product_url offer_surfaces].freeze

      def self.for_user_input(user_input_id)
        record = ScenarioUserResponseSeleniumResult.find_by(user_input_id: user_input_id)
        new(record)
      end

      def initialize(record)
        @record = record
      end

      def id
        @record&.id
      end

      def client_id
        @record&.client_id
      end

      def last_step_description
        @record&.last_step_description
      end

      def respond_to?(method_name, include_private = false)
        return true if TRACKED.include?(method_name.to_sym)

        super
      end

      def update!(attrs)
        @record&.update!(attrs)
      end

      def append_rpa_step(step)
        @record&.append_rpa_step(step)
      end

      def mark_submitted!
        return if @record.blank? || @record.order_submitted_at.present?

        @record.update!(order_submitted_at: Time.current)
      end

      def mark_done!(lexica_order_id:, last_step_no:, last_step_description:)
        return if @record.blank?
        return if @record.done?

        Order.create!(
          client_id: @record.client_id,
          scenario_id: @record.scenario_id,
          user_input_id: @record.user_input_id,
          bot_type: :web
        )
        @record.update!(
          result: :done,
          end_time: Time.current,
          last_step_no: last_step_no,
          last_step_description: last_step_description,
          lexica_order_id: lexica_order_id
        )
      end

      def mark_failed!(kind:, message:, last_step_no:, last_step_description:, screenshot_path:)
        return if @record.blank?
        return if @record.done?

        @record.update!(
          result: :error,
          end_time: Time.current,
          last_step_no: last_step_no,
          last_step_description: last_step_description,
          error_kind: kind,
          error_message: message.to_s.slice(0, 2000),
          screenshot_path: screenshot_path
        )
        Lexica::FailureMail.deliver(@record, kind, message)
        Lexica::RpaEvents.requeue_if_retryable(@record)
      end

      def upload_failure_screenshot(path, scenario_id:)
        return if @record&.id.blank? || @record.client_id.blank?

        AmazonWebServices::RpaScreenshotS3.call(
          path,
          client_id: @record.client_id,
          scenario_id: scenario_id,
          bot_order_id: @record.id
        )
      end
    end
  end
end
