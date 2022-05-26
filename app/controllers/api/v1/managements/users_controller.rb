class Api::V1::Managements::UsersController < ApplicationController
  def index
    users = User.ransack(full_name_cont: params[:name]).result
    render json: {code: 1, data: users}
  end

  def show
    user = User.find_by(id: params[:id])
    render json: {code: 1, data: user} if user.present?
    render json: {code: 2, data: "Not found"}
  end

  def update
    return render json: {code: 2, data: "Not have permission"} if current_user.admin_deel?
    user = User.find_by(id: params[:id])
    return render json: {code: 2, data: "Not found"} if user.blank?
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
