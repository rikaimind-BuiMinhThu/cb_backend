class Api::V1::MessageManagements::PersistentMenusController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :check_instagram_connect

  def index
    @persistent_menus = PersistentMenu.where(instagram_account_id: current_user.instagram_account.id)
    # render json: {code: 1, data: persistent_menus}
  end

  def create
    persistent_menu = PersistentMenu.new(persistent_menu_params)
    persistent_menu.instagram_account_id = current_user.instagram_account.id
    return render json: {code: 2, message: "Cannot create more"} unless PersistentMenu.validate_size!(persistent_menu.instagram_account_id)
    return render json: {code: 1, data: persistent_menu} if persistent_menu.save
    render json: {code: 2, message: "Something went wrong!"}
  end

  def show
    persistent_menu = PersistentMenu.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find persistent menu"} if persistent_menu.blank?
    return render json: {code: 2, message: "User can't permission"} if persistent_menu.instagram_account_id != current_user.instagram_account.id
    render json: {code: 1, data: persistent_menu}
  end

  def update
    persistent_menu = PersistentMenu.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find persistent menu"} if persistent_menu.blank?
    return render json: {code: 2, message: "User can't permission"} if persistent_menu.instagram_account_id != current_user.instagram_account.id
    if persistent_menu.update persistent_menu_params
      render json: {code: 1, data: persistent_menu}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  def destroy
    persistent_menu = PersistentMenu.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find persistent menu"} if persistent_menu.blank?
    return render json: {code: 2, message: "User can't permission"} if persistent_menu.instagram_account_id != current_user.instagram_account.id
    if persistent_menu.destroy
      render json: {code: 1, message: "Success!"}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  def status
    return render json: {code: 2, message: "User can't permission"} if current_user.instagram_account.ig_id != params[:ig_id]
    ig_access_token = InstagramAccount.find_by(ig_id: params[:ig_id]).page_access_token
    instagram_persistent_menus = HttpManager.new("https://graph.facebook.com/v11.0/me/messenger_profile?fields=persistent_menu&platform=instagram&access_token=#{ig_access_token}")
      .get_request
    render json: {code: 1, instagram_persistent_menus: instagram_persistent_menus}
  end

  def turn_on
    return render json: {code: 2, message: "User can't permission"} if current_user.instagram_account.ig_id != params[:ig_id]
    call_to_actions = []
    PersistentMenu.where(instagram_account: current_user.instagram_account).each do |persistent_menu|
      call_to_actions.push({"type": "web_url", "title": persistent_menu.title, "url": persistent_menu.url}) if persistent_menu.url.present?
      payload_hash = {message_bag_id: persistent_menu.message_bag_id, is_support: persistent_menu}
      call_to_actions.push({"type": "postback", "title": persistent_menu.title, "payload": payload_hash.to_json}) if persistent_menu.url.blank? && persistent_menu.message_bag_id.present?
    end
    return render json: {code: 2, instagram_persistent_menu: "persistent_menu is blank"} if call_to_actions.blank?
    ig_access_token = InstagramAccount.find_by(ig_id: params[:ig_id]).page_access_token
    instagram_persistent_menu = HttpManager.new(
      "https://graph.facebook.com/v11.0/me/messenger_profile?platform=instagram&access_token=#{ig_access_token}",
      {
        "persistent_menu": [{
          "locale": "default",
          "call_to_actions": call_to_actions
        }]
      }
    ).post_request
    render json: {code: 1, instagram_persistent_menu: instagram_persistent_menu}
  end

  def turn_off
    return render json: {code: 2, message: "User can't permission"} if current_user.instagram_account.ig_id != params[:ig_id]
    ig_access_token = InstagramAccount.find_by(ig_id: params[:ig_id]).page_access_token
    instagram_persistent_menu = HttpManager.new(
      "https://graph.facebook.com/v11.0/me/messenger_profile?fields=%5B'persistent_menu'%5D&platform=instagram&access_token=#{ig_access_token}"
    ).delete_request
    render json: {code: 1, instagram_persistent_menu: instagram_persistent_menu}
  end

  private

  def persistent_menu_params
    params.require(:persistent_menu).permit(:title, :message_bag_id, :url, :is_support)
  end

  def check_instagram_connect
    return render json: {code: 2, message: "You need connect instagram account first"} if current_user.instagram_account.blank?
  end
end
