class Api::V1::Managements::FileController < ApplicationController

  def index
    user_files = UserFile.select(:id, :file_url, :file_type)
                         .where(user_id: current_user.id)
    total = user_files.length
    user_files = user_files.page(params[:page])
    render json: {code: 1, data: user_files, total: total}
  end

  def create
    file_type = ''
    if ['png', 'jpg', 'jpeg'].include?(user_file_params[:file_type])
      file_type = 'image'
    elsif ['mp4'].include?(user_file_params[:file_type])
      file_type = 'mp4'
    elsif ['pdf'].include?(user_file_params[:file_type])
      file_type = 'pdf'
    end
    user_file = UserFile.new(
      file_url: user_file_params[:file_url],
      file_type: file_type,
      user_id: current_user.id
    )
    return render json: {code: 1, data: user_file} if user_file.save!
    render json: {code: 2, message: 'error'}
  end

  def destroy
    user_file = UserFile.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find file"} if user_file.blank?
    return render json: {code: 2, data: "Not have permission"} if user_file.user != current_user
    if user_file.destroy!
      AmazonWebServices::DeleteFileS3.new(user_file.file_url).call
      return render json: {code: 1, message: 'success'}
    end
    render json: {code: 2, message: 'error'}
  end

  def presinged_aws
    presigned = AmazonWebServices::UploadFileS3.new(user_file_params[:file_type],
                                                    current_user.id,
                                                    user_file_params[:size],
                                                    user_file_params[:timeplay]).call
    presigned_response = JSON.parse(presigned)
    return render json: {code: 2, message: presigned_response["message"]}, status: 500 if presigned_response["status"] == 500
    render json: {code: 1, data: presigned_response["data"]} if presigned_response["status"] == 200
  end

  private

  def user_file_params
    params.require(:user_file).permit(:file_url, :file_type, :size, :timeplay)
  end
end



