require "json"
require "net/http"
require "uri"

module SeleniumServices
  module Lexica
    class HttpResultSink
      TRACKED = %i[resolved_sku resolved_product_url offer_surfaces].freeze

      def initialize(base_url:, token:, result_id:, client_id:, last_step_description: nil)
        @base_url = base_url.to_s.sub(%r{/+\z}, "")
        @token = token.to_s
        @result_id = result_id
        @client_id = client_id
        @last_step_description = last_step_description
      end

      def id
        @result_id
      end

      def client_id
        @client_id
      end

      def last_step_description
        @last_step_description
      end

      def respond_to?(method_name, include_private = false)
        return true if TRACKED.include?(method_name.to_sym)

        super
      end

      def update!(attrs)
        payload = stringify(attrs)
        @last_step_description = payload["last_step_description"] if payload.key?("last_step_description")
        post_event("update", "attrs" => payload)
      end

      def append_rpa_step(step)
        post_event("append_step", "step" => stringify(step))
      end

      def mark_submitted!
        post_event("submitted")
      end

      def mark_done!(lexica_order_id:, last_step_no:, last_step_description:)
        @last_step_description = last_step_description
        post_event(
          "done",
          "lexica_order_id" => lexica_order_id,
          "last_step_no" => last_step_no,
          "last_step_description" => last_step_description
        )
      end

      def mark_failed!(kind:, message:, last_step_no:, last_step_description:, screenshot_path:)
        @last_step_description = last_step_description
        post_event(
          "fail",
          "error_kind" => kind,
          "error_message" => message,
          "last_step_no" => last_step_no,
          "last_step_description" => last_step_description,
          "screenshot_path" => screenshot_path
        )
      end

      def upload_failure_screenshot(path, scenario_id:)
        bucket = ENV["RPA_SCREENSHOT_BUCKET"].to_s
        return nil if bucket.empty? || id.blank? || client_id.blank?

        require "aws-sdk-s3"
        key = [
          "rpa-screenshots",
          client_id,
          scenario_id,
          "#{id}_#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}_fail.png"
        ].join("/")
        File.open(path, "rb") do |file|
          Aws::S3::Resource.new(region: ENV.fetch("AWS_REGION", "ap-northeast-1"))
            .bucket(bucket)
            .object(key)
            .put(body: file, content_type: "image/png")
        end
        key
      end

      private

      def stringify(value)
        case value
        when Hash
          value.each_with_object({}) { |(key, item), out| out[key.to_s] = stringify(item) }
        when Array
          value.map { |item| stringify(item) }
        else
          value
        end
      end

      def post_event(event, extra = {})
        uri = URI("#{@base_url}/api/internal/rpa/jobs/#{@result_id}/events")
        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{@token}"
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(extra.merge("event" => event))
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.open_timeout = 10
          http.read_timeout = 30
          http.request(request)
        end
        return if response.is_a?(Net::HTTPSuccess)

        raise "rpa event #{event} failed: #{response.code}"
      end
    end
  end
end
