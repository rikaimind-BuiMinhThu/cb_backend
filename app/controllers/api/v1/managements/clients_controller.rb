class Api::V1::Managements::ClientsController < ApplicationController
  def index
    return render json: {code: 2, data: "Not have permission"} if current_user.client?
    clients = User.where(role: [:admin_client, :client])
    clients = User.ransack(full_name_cont: params[:name]).result
    render json: {code: 1, data: clients}
  end

  def show
    return render json: {code: 2, data: "Not have permission"} if current_user.client?
    client = User.find_by(id: params[:id])
    render json: {code: 1, data: client} if client.present?
    render json: {code: 2, data: "Not found"}
  end

  def update
    return render json: {code: 2, data: "Not have permission"} if current_user.client?
    client = User.find_by(id: params[:id])
    return render json: {code: 2, data: "Not found"} if client.blank?
    return render json: {code: 1, data: "Success"} if client.update client_params
    render json: {code: 2, data: "Fail"}
  end

  def destroy
    return render json: {code: 2, data: "Not have permission"} if current_user.client? || current_user.admin_client?
    client = User.find_by(id: params[:id])
    return render json: {code: 2, data: "Not found"} if client.blank?
    return render json: {code: 1, data: "Success"} if client.destroy
    render json: {code: 2, data: "Fail"}
  end

  private

  def client_params
    params.require(:client).permit(:full_name, :phone_number, :address)
  end
end
