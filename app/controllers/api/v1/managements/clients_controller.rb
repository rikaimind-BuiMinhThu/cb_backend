class Api::V1::Managements::ClientsController < ApplicationController

  def create
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel?
    if Client.find_by_name(client_params[:name])
      render json: {:code => 2, message: t("devise.registrations.username")}
      return
    end
    client = Client.new(client_params)
    if client.save
      render json: {code: 1, message: "Success", data: client},
        status: 200
    else
      render json: {:code => 2, message: "Fail"}
    end
  end

  def index
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel?
    clients = Client.ransack(name_cont: params[:name]).result
    total = clients.size
    clients = clients.page(params[:page])
    render json: {code: 1, data: {clients: clients, total: total}}
  end

  def show
    client = Client.find_by(id: params[:id])
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && client.id == current_user.client_id)
    return render json: {code: 1, data: client} if client.present?
    render json: {code: 2, data: "Not found"}
  end

  def update
    client = Client.find_by(id: params[:id])
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && client.id == current_user.client_id)
    return render json: {code: 2, data: "Data not found"} if client.blank?
    return render json: {code: 1, data: "Success"} if client.update client_params
    render json: {code: 2, data: "Fail"}
  end

  def destroy
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel?
    client = Client.find_by(id: params[:id])
    return render json: {code: 1, data: "Success"} if client.destroy
    render json: {code: 2, data: "Fail"}
  end

  private

  def client_params
    params.require(:client).permit(:name, :address, :phone_number)
  end
end
