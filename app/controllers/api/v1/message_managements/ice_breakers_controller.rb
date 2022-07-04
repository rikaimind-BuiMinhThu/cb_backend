class Api::V1::MessageManagements::IceBreakersController < ApplicationController
  skip_before_action :verify_authenticity_token

  IGACCESSTOKEN = InstagramAccount.find_by(ig_id: "17841453981073051").page_access_token

  def index
    ice_breakers = IceBreaker.where(instagram_account_id: current_user.instagram_account.id)
    render json: {code: 1, data: ice_breakers}
  end

  def create
    ice_breaker = IceBreaker.new(ice_breaker_params)
    ice_breaker.instagram_account_id = current_user.instagram_account.id
    return render json: {code: 1, data: ice_breaker} if ice_breaker.save
    render json: {code: 2, message: "Something went wrong!"}
  end

  def show
    ice_breaker = IceBreaker.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find ice breaker"} if ice_breaker.blank?
    return render json: {code: 2, message: "User can't permission"} if ice_breaker.instagram_account_id != current_user.instagram_account.id
    render json: {code: 1, data: ice_breaker}
  end

  def update
    ice_breaker = IceBreaker.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find ice breaker"} if ice_breaker.blank?
    return render json: {code: 2, message: "User can't permission"} if ice_breaker.instagram_account_id != current_user.instagram_account.id
    if ice_breaker.update ice_breaker_params
      render json: {code: 1, data: ice_breaker}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  def destroy
    ice_breaker = IceBreaker.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find ice breaker"} if ice_breaker.blank?
    return render json: {code: 2, message: "User can't permission"} if ice_breaker.instagram_account_id != current_user.instagram_account.id
    if ice_breaker.destroy
      render json: {code: 1, message: "Success!"}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  def status
    return render json: {code: 2, message: "User can't permission"} if current_user.instagram_account.ig_id != params[:ig_id]
    instagram_ice_breakers = HttpManager.new("https://graph.facebook.com/v11.0/me/messenger_profile?fields=ice_breakers&platform=instagram&access_token=#{IGACCESSTOKEN}")
      .get_request
    render json: {code: 1, instagram_ice_breakers: instagram_ice_breakers}
  end

  def turn_on
    return render json: {code: 2, message: "User can't permission"} if current_user.instagram_account.ig_id != params[:ig_id]
    call_to_actions = []
    IceBreaker.all.each do |ice_breaker|
      call_to_actions.push({"question": ice_breaker.question, "payload": ice_breaker.answer})
    end
    instagram_ice_breaker = HttpManager.new(
      "https://graph.facebook.com/v11.0/me/messenger_profile?platform=instagram&access_token=#{IGACCESSTOKEN}",
      {
        "platform": "instagram",
        "ice_breakers": [
          {
          "call_to_actions": call_to_actions,
          "locale": "default"
        }]
      }
    ).post_request
    render json: {code: 1, instagram_ice_breaker: instagram_ice_breaker}
  end

  def turn_off
    return render json: {code: 2, message: "User can't permission"} if current_user.instagram_account.ig_id != params[:ig_id]
    instagram_ice_breaker = HttpManager.new(
      "https://graph.facebook.com/v11.0/me/messenger_profile?fields=%5B'ice_breakers'%5D&platform=instagram&access_token=#{IGACCESSTOKEN}"
    ).delete_request
    render json: {code: 1, instagram_ice_breaker: instagram_ice_breaker}
  end

  private

  def ice_breaker_params
    params.require(:ice_breaker).permit(:question, :answer)
  end
end
