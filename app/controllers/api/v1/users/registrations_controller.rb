class Api::V1::Users::RegistrationsController < ApplicationController
  def create
    return render json: {code: 2, data: "Not have permission"} if current_user.client?
    params[:user][:role] = :client
    params[:user][:client_id] = current_user.client_id if current_user.admin_client?
    user = User.new(user_params)
    if user.save
      render json: {code: 1, message: "Success"},
        status: 200
    else
      render json: {:code => 2, :message => user.errors.full_messages[0]}
    end
  end

  private
  def user_params
    params.require(:user).permit :full_name, :english_name, :email, :password, :role, :client_id
  end
end
