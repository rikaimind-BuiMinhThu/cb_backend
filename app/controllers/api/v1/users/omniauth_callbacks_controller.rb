class Api::V1::Users::OmniauthCallbacksController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  Devise.omniauth_providers.each do |provider|
    define_method provider do
      handle_with_omniauth
    end
  end

  def failure
    redirect_to after_omniauth_failure_path_for(resource_name)
    render json: {code: 2, message: "error"}
  end

  private
  def handle_with_omniauth
    begin
      if check_user_token == 2
        render json: {code: 2, message: "Fail to login."}
        return
      end
      @user = User.from_omniauth auth
      if @user.email.blank?
        tmp_user = User.find_by email: identity_hash[:uid].to_s + "@rikai.technology"
        if tmp_user.present?
          @user = tmp_user
        else
          @user.email = identity_hash[:uid].to_s + "@rikai.technology"
          @user.save
        end
      end
      @user.identities.create identity_hash
      auth_token = JsonWebToken.encode(user_id: @user.id)
      refresh_token = JsonWebToken.encode_refresh(user_id: @user.id)
      render json: {code: 1, message: "Success",
        user: @user, token: auth_token, refresh_token: refresh_token}, status: 200
    rescue
      render json: {code: 2, message: "Fail to login."}
      return
    end
  end

  def auth
    # @auth ||= request.env["omniauth.auth"]
    @auth ||= JSON.parse(@authParams.to_json, object_class: OpenStruct)
  end

  def identity_hash
    {
      provider: auth.info.provider,
      uid: auth.info.uid
    }
  end

  def check_user_token
    info = get_request "https://graph.facebook.com/me?access_token="+ params[:access_token] +
      "&fields=id,name,email,picture"
    raw_info = JSON.parse info

    if raw_info["error"].present?
      return 2
    end
    @authParams = {"info": {}}
    puts @authParams
    @authParams[:info].merge! raw_info
    @authParams[:info][:id] = raw_info["id"]
    @authParams[:info][:image] = raw_info["picture"]["data"]["url"]
    return 1
  end

  def get_request url
    require 'uri'
    require 'net/http'
    uri = URI(url)
    if res.is_a?(Net::HTTPSuccess)
      return res.body
    else
      return false
    end
  end
end
