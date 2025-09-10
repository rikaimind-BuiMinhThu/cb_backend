module AmazonWebServices
  class UploadFileS3
    require 'securerandom'

    attr_reader :type, :user_id, :size, :timeplay

    def initialize(type, user_id, size, timeplay)
      @type = type
      @user_id = user_id
      @size = size.to_i if size.present?
      @timeplay = timeplay.to_f if timeplay.present?
      @filename = SecureRandom.uuid
      @path = 'uploads/' + user_id.to_s + '/' + @filename.to_s + '.' + @type.to_s
    end

    def call
      check_type_upload_file_s3
      return {status: 500, message: 'File type not support.'}.to_json if @type_name.nil?
      validate_file_size = check_file_size_before_presigned
      return {status: 500, message: 'File is too large to upload.'}.to_json if validate_file_size == 100
      url_presigned = presigned
      return {status: 500, message: 'Invalid params.'}.to_json if url_presigned == false
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
      if ['png', 'jpg', 'jpeg', 'gif'].include?(@type)
        @type_name = 'image/' + @type
      elsif ['pdf'].include?(@type)
        @type_name = 'application/' + @type
      elsif ['mp4'].include?(@type)
        @type_name = 'video/' + @type
      else
        @type_name = nil
      end
    end

    def check_file_size_before_presigned
      return 100 if @size.blank?
      if ['png', 'jpg', 'jpeg'].include?(@type)
        return 100 if @size > (2 * 1024 * 1024)
      elsif ['pdf'].include?(@type)
        return 100 if @size > (5 * 1024 * 1024)
      elsif ['mp4'].include?(@type)
        return 100 if @timeplay.blank? || @timeplay > 15 || @size > (50 * 1024 * 1024)
      end
      return 200
    end
  end
end
