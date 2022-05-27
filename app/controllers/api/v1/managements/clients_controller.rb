class Api::V1::Managements::ClientsController < ApplicationController
  before_action :is_admin_client

  def index
    users = User.client.where(client_id: current_user.client_id)
    users = users.ransack(full_name_cont: params[:name]).result if params[:name]
    render json: {code: 1, data: users}
  end

  def show
    user = User.find_by(id: params[:id])
    return render json: {code: 2, data: "No permission"} if current_user.client_id != user.client_id
    return render json: {code: 1, data: user} if user.present?
    render json: {code: 2, data: "Data not found"}
  end

  def update
    user = User.find_by(id: params[:id])
    return render json: {code: 2, data: "No permission"} if current_user.client_id != user.client_id
    return render json: {code: 2, data: "Data not found"} if user.blank?
    return render json: {code: 1, data: "Success"} if user.update user_params
    render json: {code: 2, data: "Fail"}
  end

  def destroy
    user = User.find_by(id: params[:id])
    return render json: {code: 2, data: "No permission"} if current_user.client_id != user.client_id
    return render json: {code: 2, data: "Data not found"} if user.blank?
    return render json: {code: 1, data: "Success"} if user.destroy
    render json: {code: 2, data: "Fail"}
  end

  private

  def is_admin_client
    return render json: {code: 2, data: "No permission"} if current_user.role != "admin_client"
  end

  def user_params
    params.require(:user).permit(:full_name, :phone_number, :email)
  end
end
