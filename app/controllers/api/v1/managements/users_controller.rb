class Api::V1::Managements::UsersController < ApplicationController
  def index
    users = User.all
    render json: {code: 1, data: users}
  end

  def update
    return render json: {code: 2, data: "Not have permission"} if current_user.admin_deel?
    user = User.find_by(id: params[:id])
    return render json: {code: 1, data: "Success"} if user.update user_params
    render json: {code: 2, data: "Fail"}
  end

  def destroy
    return render json: {code: 2, data: "Not have permission"} if current_user.admin_deel?
    return render json: {code: 2, data: "Cannot update current user"} if current_user.id == params[:id]
    user = User.find_by(id: params[:id])
    return render json: {code: 1, data: "Success"} if user.destroy
    render json: {code: 2, data: "Fail"}
  end

  private

  def user_params
    params.require(:user).permit(:full_name)
  end
end
