class Api::V1::InstagramSettingsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :permision

  def connect
    result = FacebookManager::InstagramSetting.new(params[:fb_AuthResponse], params[:page_id], params[:ig_id], 1).connect
    return render json: {code: 2, message: result.to_s} if result != 1
    render json: {code: 1, message: "Success!"}
  end
end
