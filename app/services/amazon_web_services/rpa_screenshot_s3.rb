module AmazonWebServices
  class RpaScreenshotS3
    KEY_PREFIX = "rpa-screenshots/"

    def self.call(local_path, client_id:, scenario_id:, bot_order_id:)
      new(local_path, client_id: client_id, scenario_id: scenario_id, bot_order_id: bot_order_id).call
    end

    def self.s3_key?(path)
      path.to_s.start_with?(KEY_PREFIX)
    end

    def self.read(key)
      object(key).get.body.read
    end

    def self.object(key)
      s3 = Aws::S3::Resource.new(
        credentials: Aws::Credentials.new(Settings.aws.s3.AWS_ACCESS_KEY_ID, Settings.aws.s3.AWS_SECRET_ACCESS_KEY),
        region: Settings.aws.s3.AWS_REGION
      )
      s3.bucket(Settings.aws.s3.S3_BUCKET).object(key)
    end

    def initialize(local_path, client_id:, scenario_id:, bot_order_id:)
      @local_path = local_path
      @client_id = client_id
      @scenario_id = scenario_id
      @bot_order_id = bot_order_id
    end

    def call
      key = [
        "rpa-screenshots",
        @client_id,
        @scenario_id,
        "#{@bot_order_id}_#{timestamp}_fail.png"
      ].join("/")
      File.open(@local_path, "rb") do |file|
        self.class.object(key).put(body: file, content_type: "image/png")
      end
      key
    end

    private

    def timestamp
      Time.current.utc.strftime("%Y%m%dT%H%M%SZ")
    end
  end
end
