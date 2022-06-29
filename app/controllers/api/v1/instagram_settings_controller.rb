class Api::V1::InstagramSettingsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    instagram_accounts = InstagramAccount.where(user_id: current_user.id)
    render json: {code: 1, data: instagram_accounts}
  end

  def show
    instagram_account = InstagramAccount.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find instagram setting"} if instagram_account.blank?
    return render json: {code: 2, data: "User can't permission"} if instagram_account.user_id != current_user.id
    render json: {code: 1, data: instagram_account}
  end

  def connect
    result = FacebookManager::InstagramSetting.new(params[:fb_AuthResponse], params[:page_id], params[:ig_id], 1).connect
    return render json: {code: 2, message: result.to_s} if result != 1
    render json: {code: 1, message: "Success!"}
  end

  def destroy
    instagram_account = InstagramAccount.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find instagram setting"} if instagram_account.blank?
    return render json: {code: 2, data: "User can't permission"} if instagram_account.user_id != current_user.id
    if instagram_account.destroy
      render json: {code: 1, data: "Success!"}
    else
      render json: {code: 2, data: "Fail!"}
    end
  end
end
