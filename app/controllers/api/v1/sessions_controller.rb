class Api::V1::SessionsController < ApplicationController
  skip_before_action :permision, only: :create
  before_action :load_user_authentication
  skip_before_action :verify_authenticity_token

  respond_to :json

  def create
    auth_token = JsonWebToken.encode(user_id: @user.id)
    render json: {code: 1, message: t("devise.confirmations.signed_in"),
      user: @user, token: auth_token}, status: 200
  end

  private
  def user_params
    # params.require(:user).permit :username, :password
    params.require(:user).permit :email, :password
  end
end
