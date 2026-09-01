class Api::V1::MessageManagements::PersistentMenusController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :check_instagram_connect

  def index
    @persistent_menus = PersistentMenu.where(instagram_account_id: current_user.instagram_account.id)
                                      .includes(:message_bag)
  end

  def create
    persistent_menu = PersistentMenu.new(normalized_persistent_menu_params)
    persistent_menu.instagram_account_id = current_user.instagram_account.id
    return render json: {code: 2, message: "Cannot create more"} unless PersistentMenu.validate_size!(persistent_menu.instagram_account_id)
    return render json: {code: 1, data: persistent_menu} if persistent_menu.save
    render json: {code: 2, message: persistent_menu.errors.full_messages}
  end

  def show
    persistent_menu = PersistentMenu.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find persistent menu"} if persistent_menu.blank?
    return render json: {code: 2, message: "User can't permission"} if persistent_menu.instagram_account_id != current_user.instagram_account.id
    render json: {code: 1, data: persistent_menu}
  end

  def update
    persistent_menu = PersistentMenu.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find persistent menu"} if persistent_menu.blank?
    return render json: {code: 2, message: "User can't permission"} if persistent_menu.instagram_account_id != current_user.instagram_account.id
    if persistent_menu.update normalized_persistent_menu_params
      render json: {code: 1, data: persistent_menu}
    else
      render json: {code: 2, message: persistent_menu.errors.full_messages}
    end
  end

  def destroy
    persistent_menu = PersistentMenu.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find persistent menu"} if persistent_menu.blank?
    return render json: {code: 2, message: "User can't permission"} if persistent_menu.instagram_account_id != current_user.instagram_account.id
    if persistent_menu.destroy
      render json: {code: 1, message: "Success!"}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  def status
    return render json: {code: 2, message: "User can't permission"} unless authorized_for_ig?(params[:ig_id])

    result = messenger_profile_service(params[:ig_id]).persistent_menu_status
    return render_meta_error(result) unless result[:success]

    render json: {code: 1, instagram_persistent_menus: result[:data]}
  end

  def turn_on
    return render json: {code: 2, message: "User can't permission"} unless authorized_for_ig?(params[:ig_id])

    call_to_actions = build_persistent_menu_actions
    return render json: {code: 2, instagram_persistent_menu: "persistent_menu is blank"} if call_to_actions.blank?

    result = messenger_profile_service(params[:ig_id]).publish_persistent_menu(call_to_actions)
    return render_meta_error(result) unless result[:success]

    render json: {code: 1, instagram_persistent_menu: result[:data]}
  end

  def turn_off
    return render json: {code: 2, message: "User can't permission"} unless authorized_for_ig?(params[:ig_id])

    result = messenger_profile_service(params[:ig_id]).remove_persistent_menu
    return render_meta_error(result) unless result[:success]

    render json: {code: 1, instagram_persistent_menu: result[:data]}
  end

  private

  def persistent_menu_params
    params.require(:persistent_menu).permit(:title, :message_bag_id, :url, :is_support)
  end

  def normalized_persistent_menu_params
    attrs = persistent_menu_params.to_h
    attrs['message_bag_id'] = attrs['message_bag_id'].presence if attrs.key?('message_bag_id')
    attrs
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

  def build_persistent_menu_actions
    PersistentMenu.where(instagram_account: current_user.instagram_account).flat_map do |persistent_menu|
      actions = []
      if persistent_menu.url.present?
        actions << { type: 'web_url', title: persistent_menu.title, url: persistent_menu.url }
      elsif persistent_menu.message_bag_id.present?
        payload_hash = { message_bag_id: persistent_menu.message_bag_id, is_support: persistent_menu.is_support }
        actions << { type: 'postback', title: persistent_menu.title, payload: payload_hash.to_json }
      end
      actions
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
