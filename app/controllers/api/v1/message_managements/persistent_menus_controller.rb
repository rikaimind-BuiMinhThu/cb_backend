class Api::V1::MessageManagements::PersistentMenusController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  IGACCESSTOKEN = InstagramAccount.find_by(ig_id: "17841453981073051").page_access_token

  def index
    render json: {code: 1, data: PersistentMenu.all}
  end

  def create
    persistent_menu = PersistentMenu.create(persistent_menu_params)
    render json: {code: 1, data: persistent_menu}
  end

  def show
    persistent_menu = PersistentMenu.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find ice breaker"} if persistent_menu.blank?
    render json: {code: 1, data: persistent_menu}
  end

  def update
    persistent_menu = PersistentMenu.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find ice breaker"} if persistent_menu.blank?
    persistent_menu.update persistent_menu_params
    render json: {code: 1, data: persistent_menu}
  end

  def destroy
    persistent_menu = PersistentMenu.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find ice breaker"} if persistent_menu.blank?
    persistent_menu.destroy
    render json: {code: 1, data: persistent_menu}
  end

  def status
    instagram_persistent_menus = HttpManager.new("https://graph.facebook.com/v11.0/me/messenger_profile?fields=persistent_menu&platform=instagram&access_token=#{IGACCESSTOKEN}")
      .get_request
    render json: {code: 1, instagram_persistent_menus: instagram_persistent_menus}
  end

  def turn_on
    call_to_actions = []
    PersistentMenu.all.each do |persistent_menu|
      call_to_actions.push({"type": "web_url", "title": persistent_menu.title, "url": persistent_menu.url}) if persistent_menu.url.present?
      call_to_actions.push({"type": "postback", "title": persistent_menu.title, "payload": persistent_menu.payload}) if persistent_menu.url.blank? && persistent_menu.payload.present?
    end
    instagram_persistent_menu = HttpManager.new(
      "https://graph.facebook.com/v11.0/me/messenger_profile?platform=instagram&access_token=#{IGACCESSTOKEN}",
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
    instagram_persistent_menu = HttpManager.new(
      "https://graph.facebook.com/v11.0/me/messenger_profile?fields=['persistent_menu']&platform=instagram&access_token=#{IGACCESSTOKEN}",
    ).delete_request
    render json: {code: 1, instagram_persistent_menu: instagram_persistent_menu}
  end

  private

  def persistent_menu_params
    params.require(:persistent_menu).permit(:title, :payload, :url)
  end
end
