module AmazonWebServices
  class DeleteFileS3

    attr_reader :file_url

    def initialize(file_url)
      @file_url = file_url
    end

    def call
      delete_file_s3
    end

    private

    def delete_file_s3
      if @file_url.present?
        begin
          s3 = Aws::S3::Resource.new(
            credentials: Aws::Credentials.new(Settings.aws.s3.AWS_ACCESS_KEY_ID, Settings.aws.s3.AWS_SECRET_ACCESS_KEY),
            region: Settings.aws.s3.AWS_REGION
          )
          bucket = s3.bucket(Settings.aws.s3.S3_BUCKET)
          obj = bucket.object(@file_url)
          obj.delete
          return true
        rescue Exception => e
          return false
        end
      else
        return false
      end
    end
  end
end
