class Api::V1::SessionsController < ApplicationController
  skip_before_action :permision, only: [:create, :new]
  before_action :load_user_authentication, only: [:create]
  skip_before_action :verify_authenticity_token

  respond_to :json

  def new
  end

  def create
    auth_token = JsonWebToken.encode(user_id: @user.id)
    refresh_token = JsonWebToken.encode_refresh(user_id: @user.id)
    client = @user.client
    render json: {code: 1, message: "Success",
      user: @user, token: auth_token, refresh_token: refresh_token,
      client: client
    }, status: 200
  end

  private
  def user_params
    # params.require(:user).permit :username, :password
    params.require(:user).permit :email, :password
  end
end
