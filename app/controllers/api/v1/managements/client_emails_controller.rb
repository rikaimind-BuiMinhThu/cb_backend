class Api::V1::Managements::ClientEmailsController < ApplicationController

  def index
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    @client_emails = ClientEmail.all
    @total = @client_emails.length
    @client_emails = @client_emails.page(params[:page])
    # render json: {code: 1, data: emails}
  end

  def create
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    email = ClientEmail.new(email_params)
    email.client_id = params[:client_id]
    return render json: {code: 1, message: "Success"} if email.save
    render json: {code: 2, message: email.errors.full_messages}
  end

  def update
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    email = ClientEmail.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find email"} if email.blank?
    return render json: {code: 1, message: "Success"} if email.update(email_params)
    render json: {code: 2, message: email.errors.full_messages}
  end

  def destroy
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    email = ClientEmail.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find email"} if email.blank?
    return render json: {code: 1, message: "Success"} if email.destroy
    render json: {code: 2, message: email.errors.full_messages}
  end

  private

  def email_params
    params.require(:email).permit(:email, :password)
  end
end
