class Api::V1::Managements::PaymentHistoriesController < ApplicationController
  def create
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    

    PaymentHistory.transaction do
      if(params[:payment].present?)
        @payment = PaymentHistory.new(payment_params)
        if @payment.save!
          render json: {code: 1, message: "Success"}
        end
      else
        scenario = Scenario.find(scenario_id)
        client = scenario.chatbot&.user&.client
          @payment = PaymentHistory.new()
          @payment.client_id = client.id
          @payment.status = 0
          @payment.start_at = client.subscription_start_at
          @payment.end_at = client.subscription_end_at
          if @payment.save!
            render json: {code: 1, message: "Success"}
          end
        end
      end
    rescue Exception => e
      return render json: {code: 2, message: e}
  end

  def show
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    puts("Client id "+params[:id])
    @paymens = PaymentHistory.ransack(client_id_eq: params[:id]).result
    @total = @paymens.size
    @paymens = @paymens.page(params[:page]).per(20)
    render json: {code: 1, data: @paymens, total: @total}
  end

  def update
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    payment = PaymentHistory.find_by(id: params[:id])
    return render json: {code: 2, message: "Data not found"} if payment.blank?
    params[:payment][:status] = params[:payment][:status] if params[:payment][:status].present?
    params[:payment][:start_at] = params[:payment][:start_at] if params[:payment][:start_at].present?
    params[:payment][:end_at] = params[:payment][:end_at] if params[:payment][:end_at].present?
    params[:payment][:paid_at] = params[:payment][:paid_at] if params[:payment][:paid_at].present?
    if params[:payment][:status] == 'unpaid' 
      params[:payment][:paid_at] = nil
    end
    return render json: {code: 1, message: "Success"} if payment.update payment_params
    render json: {code: 2, message: "Fail"}

  end

  def destroy
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    payment = PaymentHistory.find_by(id: params[:id])
    return render json: {code: 1, message: "Success"} if payment.destroy
    render json: {code: 2, message: "Fail"}
  end

  private
  def payment_params 
    params.fetch(:payment, nil).permit(:client_id, :start_at, :end_at, :paid_at, :status)
  end
end
