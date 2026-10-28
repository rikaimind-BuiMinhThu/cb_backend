require "json"

module Lexica
  class RpaQueue
    def self.lambda_runtime?
      ENV["LEXICA_RPA_RUNTIME"].to_s == "lambda" && ENV["LEXICA_RPA_QUEUE_URL"].to_s != ""
    end

    def self.message_body(result_id)
      JSON.generate("selenium_result_id" => result_id.to_i)
    end

    def self.enqueue(result_id, delay_seconds: 0)
      require "aws-sdk-sqs"
      Aws::SQS::Client.new(region: ENV.fetch("AWS_REGION", "ap-northeast-1")).send_message(
        queue_url: ENV.fetch("LEXICA_RPA_QUEUE_URL"),
        message_body: message_body(result_id),
        delay_seconds: delay_seconds
      )
    end
  end
end
