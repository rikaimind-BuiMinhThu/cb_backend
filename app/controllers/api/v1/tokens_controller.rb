class Api::V1::TokensController < ApplicationController
  skip_before_action :permision, only: :create
  before_action :permision_refresh

  def create
    auth_token = JsonWebToken.encode(user_id: @current_user.id)
    render json: {code: 1, message: "Success",
                  token: auth_token}, status: 200
  end

  private

  def authenticate_refresh_token!
    token = request.headers['Authorization'].split(' ').last rescue nil
    payload = token.nil? ? nil : JsonWebToken.decode_refresh(token) rescue nil
    if payload.nil? || !JsonWebToken.valid_payload_refresh(payload.first)
      return render json: {code: 0,
        message: "You need to sign in before continuing."}, status: 401
    end
    @current_user = User.find_by_id payload.first["user_id"]
  end

  def permision_refresh
    authenticate_refresh_token!
  end
end
