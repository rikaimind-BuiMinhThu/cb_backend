class Api::V1::Users::RegistrationsController < ApplicationController
  skip_before_action :permision
  respond_to :json

  def create
    if User.find_by_email(user_params[:email])
      render json: {:code => 2, message: t("devise.registrations.username")}
      return
    end
    params[:user][:role] = :client
    user = User.new(user_params)
    if user.save
      user.update role: :client
      render json: {code: 1, message: t("devise.registrations.signed_up_but_unconfirmed")},
        status: 200
    else
      render json: {:code => 2, :message => user.errors.full_messages[0]}
    end
  end

  private
  def user_params
    params.require(:user).permit :first_name, :last_name, :email, :password, :role
  end
end
