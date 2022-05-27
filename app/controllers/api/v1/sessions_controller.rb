class Api::V1::SessionsController < ApplicationController
  skip_before_action :permision, only: :create
  before_action :load_user_authentication

  respond_to :json

  def create
    auth_token = JsonWebToken.encode(user_id: @user.id)
    refresh_token = JsonWebToken.encode_refresh(user_id: @user.id)
    render json: {code: 1, message: "Success",
      user: @user, token: auth_token, refresh_token: refresh_token}, status: 200
  end

  private
  def user_params
    # params.require(:user).permit :username, :password
    params.require(:user).permit :email, :password
  end
end
