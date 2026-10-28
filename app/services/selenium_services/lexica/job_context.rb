module SeleniumServices
  module Lexica
    class JobContext
      Conversation = Struct.new(:data_input_name, :value, :user_input_id, keyword_init: true)

      class ScenarioContext
        def initialize(attrs)
          @attrs = attrs.each_with_object({}) { |(key, value), out| out[key.to_s] = value }
        end

        def respond_to_missing?(name, include_private = false)
          key = name.to_s
          @attrs.key?(key) || key.start_with?("lexica_offer_") || super
        end

        def method_missing(name, *args)
          key = name.to_s
          return @attrs[key] if @attrs.key?(key)
          return false if key.start_with?("lexica_offer_")
          return nil if key == "tamago_repeat_config"

          super
        end

        def id
          @attrs["id"]
        end
      end

      def self.from_job(job)
        data = job.respond_to?(:to_h) ? job : {}
        scenario = ScenarioContext.new(data["scenario"] || data[:scenario] || {})
        rows = data["conversations"] || data[:conversations] || []
        user_input_id = data["user_input_id"] || data[:user_input_id]
        conversations = Array(rows).map do |row|
          item = row.respond_to?(:to_h) ? row.to_h : row
          Conversation.new(
            data_input_name: item["data_input_name"] || item[:data_input_name],
            value: item.key?("value") ? item["value"] : item[:value],
            user_input_id: item["user_input_id"] || item[:user_input_id] || user_input_id
          )
        end
        [scenario, conversations]
      end
    end
  end
end
