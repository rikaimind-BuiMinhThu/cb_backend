class Api::V1::PaymentManagements::PaymentGatewaysController < ApplicationController
  RETURN_FIELDS = [:id, :gateway_name, :payment_agency, :mode, :shop_id,
    :merchant_code, :sp_code, :terminal_id, :client_ip, :store_id, :user_id, :is_default]
  def index
    payment_gateways = PaymentGateway.select(RETURN_FIELDS)
                                     .where(user_id: current_user.id)
    total = payment_gateways.length
    payment_gateways = payment_gateways.page(params[:page]) if params[:page] != 'all'
    render json: {code: 1, data: payment_gateways, total: total}
  end

  def show
    payment = find_payment
    return if payment.blank?
    render json: {code: 1, data: payment}
  end

  def create
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    payment = PaymentGateway.new(payment_create_params)
    payment.user = current_user
    payment.is_default = :yes if current_user.payment_gateways.is_default_yes.blank?
    return render json: {code: 1, data: payment} if payment.save
    render json: {code: 2, messages: payment.errors.full_messages}
  end

  def update
    payment = find_payment
    return if payment.blank?
    ActiveRecord::Base.transaction do
      if payment_update_params[:is_default] == 'yes'
        current_user.payment_gateways.where.not(id: payment.id).each do |payment_gateway|
          payment_gateway.update!(is_default: :no)
        end
      end
      payment.update!(payment_update_params)
      render json: {code: 1, data: payment}
    rescue
      Rails.logger.error(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      render json: {code: 2, message: error}
    end
  end

  def destroy
    payment = find_payment
    return if payment.blank?
    ActiveRecord::Base.transaction do
      payment.destroy!
      current_user.payment_gateways.first&.update(is_default: :yes)
      render json: {code: 1, data: payment}
    rescue
      Rails.logger.error(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      render json: {code: 2, message: error}
    end
  end

  private

  def payment_create_params
    params.require(:payment).permit(:gateway_name, :payment_agency, :mode, :shop_id, :shop_pass,
      :merchant_code, :sp_code, :terminal_id, :client_ip, :store_id)
  end

  def payment_update_params
    params.require(:payment).permit(:gateway_name, :payment_agency, :mode, :shop_id, :shop_pass,
      :merchant_code, :sp_code, :terminal_id, :client_ip, :store_id, :is_default)
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
