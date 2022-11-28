class Api::V1::PaymentManagements::PaymentManagementsController < ApplicationController
  def show
    find_chatbot
    return if @chatbot.blank?
  end

  def update_consumption_tax
    find_chatbot(true)
    return if @chatbot.blank?
    return render json: {code: 1, data: "Success"} if @chatbot.update(consumption_tax_params)
    render json: {code: 2, data: @chatbot.errors.full_messages}
  end

  def update_specify_payment_gateway
    find_chatbot(true)
    return if @chatbot.blank?
    ActiveRecord::Base.transaction do
      @chatbot.specify_payment_variables.each { |specify_payment_variable| specify_payment_variable.destroy! }
      @chatbot.update!(specify_payment_gateway_params)
      params[:specify_payment_gateway][:variables].each do |variable|
        specify_payment = SpecifyPaymentVariable.new(specify_payment_variable(variable))
        specify_payment.chatbot = @chatbot
        specify_payment.save!
      end
      render json: {code: 1, message: "success"}
    rescue StandardError => error
      Rails.logger.error(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      render json: {code: 2, message: error}
    end
  end

  def update_settlement_fee
    find_chatbot(true)
    return if @chatbot.blank?
    ActiveRecord::Base.transaction do
      @chatbot.settlement_fee_variables.each { |settlement_fee_variable| settlement_fee_variable.destroy! }
      @chatbot.update!(settlement_fee_params)
      params[:settlement_fee][:variables].each do |variable|
        settlement_fee = SettlementFeeVariable.new(settlement_fee_variable(variable))
        settlement_fee.chatbot = @chatbot
        settlement_fee.save!
      end
      render json: {code: 1, message: "success"}
    rescue StandardError => error
      Rails.logger.error(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      render json: {code: 2, message: error}
    end
  end

  def update_shipping_fee
    find_chatbot(true)
    return if @chatbot.blank?
    ActiveRecord::Base.transaction do
      @chatbot.shipping_fee_variables.each { |shipping_fee_variable| shipping_fee_variable.destroy! }
      @chatbot.update!(shipping_fee_params)
      params[:shipping_fee][:variables].each do |variable|
        shipping_fee = ShippingFeeVariable.new(shipping_fee_variable(variable))
        shipping_fee.chatbot = @chatbot
        shipping_fee.save!
      end
      render json: {code: 1, message: "success"}
    rescue StandardError => error
      Rails.logger.error(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      render json: {code: 2, message: error}
    end
  end

  def update_np_deferred_payment
    find_chatbot(true)
    return if @chatbot.blank?
    return render json: {code: 1, data: "Success"} if @chatbot.update(np_deferred_payment_params)
    render json: {code: 2, data: @chatbot.errors.full_messages}
  end

  private

  def consumption_tax_params
    params.require(:consumption_tax).permit(:include_tax, :sale_tax_rate, :calculate_one_yen)
  end

  def specify_payment_gateway_params
    params.require(:specify_payment_gateway).permit(:can_specify_payment, :specify_payment_variable_id)
  end

  def specify_payment_variable(variable)
    variable.permit(:variable_value, :payment_gateway_id)
  end

  def settlement_fee_params
    params.require(:settlement_fee).permit(:need_paid_settlement_fee, :settlement_fee_variable_id)
  end

  def settlement_fee_variable(variable)
    variable.permit(:variable_value, :commission)
  end

  def shipping_fee_params
    params.require(:shipping_fee).permit(:need_paid_shipping_fee, :shipping_fee_variable_id)
  end

  def shipping_fee_variable(variable)
    variable.permit(:prefecture_id, :amount)
  end

  def np_deferred_payment_params
    params.require(:np_deferred_payment).permit(:need_np_deferred_payment, :np_invoice_included, :np_maximum_amount, :np_settlement_min_value, :np_settlement_max_value, :np_settlement_fee_value)
  end

  def find_chatbot(editor_permission = false)
    render json: {code: 2, data: "No permission"} and return unless current_user.admin_deel? || current_user.admin_client?
    @chatbot = Chatbot.find_by(id: params[:id])
    render json: {code: 2, message: "Cannot find chatbot"} and return if @chatbot.blank?
    render json: {code: 2, data: "No permission"} and return if current_user.admin_client? && @chatbot.user_chatbots.where(roles: [:bot_admin, :editor, :reader]).pluck(:user_id).include?(current_user.id)
    @chatbot
  end
end
