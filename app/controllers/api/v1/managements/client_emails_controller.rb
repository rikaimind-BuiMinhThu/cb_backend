class Api::V1::Managements::ClientEmailsController < ApplicationController
  def index
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    emails = ClientEmail.all
    emails = emails.where(client: current_user.client) if current_user.admin_client?
    emails = emails.pluck(:id, :email)
    render json: {code: 1, data: emails}
  end

  def create
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    email = ClientEmail.new(email_params)
    return render json: {code: 1, message: "Success"} if email.save
    render json: {code: 2, message: email.errors.full_messages}
  end

  def update
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    email = ClientEmail.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find email"} if email.blank?
    return render json: {code: 2, data: "No permission"} if current_user.admin_client? && email.client_id != current_user.client_id
    return render json: {code: 1, message: "Success"} if email.update(email_params)
    render json: {code: 2, message: email.errors.full_messages}
  end

  def destroy
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    email = ClientEmail.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find email"} if email.blank?
    return render json: {code: 2, data: "No permission"} if current_user.admin_client? && email.client_id != current_user.client_id
    return render json: {code: 1, message: "Success"} if email.destroy
    render json: {code: 2, message: email.errors.full_messages}
  end

  private

  def email_params
    params.require(:email).merge!(client_id: current_user.client_id).permit(:email, :password)
  end
end
