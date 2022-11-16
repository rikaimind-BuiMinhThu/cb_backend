module AmazonWebServices
  class UploadFileS3
    require 'securerandom'

    attr_reader :type, :user_id

    def initialize(type, user_id)
      @type = type
      @user_id = user_id
      @filename = SecureRandom.uuid
      @path = 'uploads/' + user_id.to_s + '/' + @filename.to_s + '.' + @type.to_s
    end

    def call
      check_type_upload_file_s3
      return {status: 500, message: 'File type not support.'}.to_json if @type_name.nil?
      url_presigned = presigned
      return {status: 500, message: 'Invalid Params'}.to_json if url_presigned == false
      return {status: 200, data: {url: url_presigned, path: @path}}.to_json
    end

    private

    def presigned
      if @type_name.present? && @user_id.present?
        s3 = Aws::S3::Resource.new(
          credentials: Aws::Credentials.new(Settings.aws.s3.AWS_ACCESS_KEY_ID, Settings.aws.s3.AWS_SECRET_ACCESS_KEY),
          region: Settings.aws.s3.AWS_REGION
        )
        obj = s3.bucket(Settings.aws.s3.S3_BUCKET).object(@path)
        psu = obj.presigned_url(:put_object, :content_type => @type_name, :expires_in => 10*60)
        url = URI.parse(psu)
        return url
      else
        return false
      end
    end

    def check_type_upload_file_s3
      if ['png', 'jpg', 'jpeg'].include?(@type)
        @type_name = 'image/' + @type
      elsif ['pdf'].include?(@type)
        @type_name = 'application/' + @type
      elsif ['mp4'].include?(@type)
        @type_name = 'video/' + @type
      else
        @type_name = nil
      end
    end
  end
end
