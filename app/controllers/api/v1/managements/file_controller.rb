class Api::V1::Managements::FileController < ApplicationController

  def index
    user_files = UserFile.select(:id, :file_url, :file_type)
                         .where(user_id: current_user.id)
    total = user_files.length
    user_files = user_files.page(params[:page])
    render json: {code: 1, data: user_files, total: total}
  end

  def create
    user_file = UserFile.new(
      file_url: user_file_params[:file_url],
      file_type: ['png', 'jpg', 'jpeg'].include?(user_file_params[:file_type]) ? 'image' : '',
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
    presigned = AmazonWebServices::UploadFileS3.new(user_file_params[:file_type], current_user.id).call
    presigned_response = JSON.parse(presigned)
    return render json: {code: 2, message: presigned_response["message"]}, status: 500 if presigned_response["status"] == 500
    render json: {code: 1, data: presigned_response["data"]} if presigned_response["status"] == 200
  end

  private

  def user_file_params
    params.require(:user_file).permit(:file_url, :file_type)
  end
end



