class Api::V1::PaymentManagements::PaymentGatewaysController < ApplicationController
  RETURN_FIELDS = [:id, :gateway_name, :payment_agency, :mode, :shop_id,
      :merchant_code, :client_ip, :store_id, :user_id]
  def index
    render json: {code: 1, data: current_user.payment_gateways.select(RETURN_FIELDS)}
  end

  def show
    payment = find_payment
    return if payment.blank?
    render json: {code: 1, data: payment}
  end

  def create
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    payment = PaymentGateway.new(payment_params)
    payment.user = current_user
    return render json: {code: 1, data: payment} if payment.save
    render json: {code: 2, messages: payment.errors.full_messages}
  end

  def update
    payment = find_payment
    return if payment.blank?
    return render json: {code: 1, data: payment} if payment.update(payment_params)
    render json: {code: 2, messages: payment.errors.full_messages}
  end

  def destroy
    payment = find_payment
    return if payment.blank?
    return render json: {code: 1, data: payment} if payment.destroy
    render json: {code: 2, messages: payment.errors.full_messages}
  end

  private

  def payment_params
    params.require(:payment).permit(:gateway_name, :payment_agency, :mode, :shop_id, :shop_pass,
      :merchant_code, :sp_code, :terminal_id, :client_ip, :store_id)
  end

  def find_payment
    unless current_user.admin_deel? || current_user.admin_client?
      return render json: {code: 2, message: "No permission"}
      return nil
    end
    payment = PaymentGateway.select(RETURN_FIELDS).find_by(id: params[:id])
    if payment.blank?
      render json: {code: 2, message: "No permission"} if payment.blank?
      return nil
    end
    if payment.user != current_user
      render json: {code: 2, message: "No permission"}
      return nil
    end
    payment
  end
end
