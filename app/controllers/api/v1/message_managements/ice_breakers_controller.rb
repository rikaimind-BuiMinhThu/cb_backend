class Api::V1::MessageManagements::IceBreakersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :check_instagram_connect

  def index
    @ice_breakers = IceBreaker.where(instagram_account_id: current_user.instagram_account.id)
                              .includes(:message_bag)
  end

  def create
    ice_breaker = IceBreaker.new(ice_breaker_params)
    ice_breaker.instagram_account_id = current_user.instagram_account.id
    return render json: {code: 2, message: "Cannot create more"} unless IceBreaker.validate_size!(ice_breaker.instagram_account_id)
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
    return render json: {code: 2, message: "Cannot find ice breaker"} if ice_breaker.blank?
    return render json: {code: 2, message: "User can't permission"} if ice_breaker.instagram_account_id != current_user.instagram_account.id
    if ice_breaker.destroy
      render json: {code: 1, message: "Success!"}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  def status
    return render json: {code: 2, message: "User can't permission"} unless authorized_for_ig?(params[:ig_id])

    result = messenger_profile_service(params[:ig_id]).ice_breakers_status
    return render_meta_error(result) unless result[:success]

    render json: {code: 1, instagram_ice_breakers: result[:data]}
  end

  def turn_on
    return render json: {code: 2, message: "User can't permission"} unless authorized_for_ig?(params[:ig_id])

    call_to_actions = build_ice_breaker_actions
    return render json: {code: 2, instagram_persistent_menu: "ice_breaker is blank"} if call_to_actions.blank?

    result = messenger_profile_service(params[:ig_id]).publish_ice_breakers(call_to_actions)
    return render_meta_error(result) unless result[:success]

    render json: {code: 1, instagram_ice_breaker: result[:data]}
  end

  def turn_off
    return render json: {code: 2, message: "User can't permission"} unless authorized_for_ig?(params[:ig_id])

    result = messenger_profile_service(params[:ig_id]).remove_ice_breakers
    return render_meta_error(result) unless result[:success]

    render json: {code: 1, instagram_ice_breaker: result[:data]}
  end

  private

  def ice_breaker_params
    params.require(:ice_breaker).permit(:question, :message_bag_id)
  end

  def check_instagram_connect
    return render json: {code: 2, message: "You need connect instagram account first"} if current_user.instagram_account.blank?
  end

  def authorized_for_ig?(ig_id)
    current_user.instagram_account.ig_id == ig_id
  end

  def messenger_profile_service(ig_id)
    access_token = InstagramAccount.find_by(ig_id: ig_id).page_access_token
    FacebookManager::MessengerProfileService.new(access_token)
  end

  def build_ice_breaker_actions
    IceBreaker.where(instagram_account: current_user.instagram_account).map do |ice_breaker|
      payload_hash = { message_bag_id: ice_breaker.message_bag_id }
      { question: ice_breaker.question, payload: payload_hash.to_json }
    end
  end

  def render_meta_error(result)
    render json: {
      code: 2,
      message: result.dig(:error, :message) || 'Meta API request failed',
      meta_error: result[:error]
    }
  end
end
