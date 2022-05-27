class Api::V1::ClientsController < ApplicationController
  before_action :is_admin_deel

  def create
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

  def show
    client = Client.find_by(id: params[:id])
    return render json: {code: 1, data: client} if client.present?
    render json: {code: 2, data: "Data not found"}
  end

  def update
    client = Client.find_by(id: params[:id])
    return render json: {code: 2, data: "Data not found"} if client.blank?
    return render json: {code: 1, data: "Success"} if client.update client_params
    render json: {code: 2, data: "Fail"}
  end

  private

  def is_admin_deel
    return render json: {code: 2, data: "No permission"} if current_user.role != "admin_deel"
  end

  def client_params
    params.require(:client).permit(:name, :address, :phone_number)
  end
end
