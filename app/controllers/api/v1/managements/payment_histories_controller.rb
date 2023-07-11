class Api::V1::Managements::PaymentHistoriesController < ApplicationController
  def create
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    PaymentHistory.transaction do
      if(params[:payment].present?)
        current_date = Date.today
        end_at = DateTime.parse(payment_params[:end_at]).to_date

        if (current_date >= end_at)
          client = Client.find_by(id: payment_params[:client_id])
          is_break = false
          payment_params_list = []
          payment_params_list.push({
                                     client_id: payment_params[:client_id],
                                     start_at: payment_params[:start_at],
                                     end_at: payment_params[:end_at],
                                     paid_at: payment_params[:paid_at],
                                     status: payment_params[:status],
                                     price: client.plan == 4 ? 0 : client.price
                                   })
          while !is_break
            if (current_date <= end_at)
              is_break = true
              break
            end
            start_at = end_at + 1.day
            end_at = (start_at + 1.month) - 1.day
            price = 0
            if(current_date > end_at)
              price = client.price
            end
            payment_params_list.push({
                                       client_id: payment_params[:client_id],
                                       start_at: start_at,
                                       end_at: end_at,
                                       paid_at: payment_params[:paid_at],
                                       status: payment_params[:status],
                                       price: client.plan == 4 ? 0 : price
                                     })
          end
          payment_params_list.each do |params|
            @payment = PaymentHistory.new(params)
            @payment.save!
          end
          render json: {code: 1, message: "Success"}
        else
          @payment = PaymentHistory.new(payment_params)
          if @payment.save!
            render json: {code: 1, message: "Success"}
          end
        end
      end
    rescue Exception => e
      return render json: {code: 2, message: e}
    end
  end

  def show
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    client = Client.find_by_id(params[:id])
    @paymens = PaymentHistory.ransack(client_id_eq: params[:id]).result
    @total = @paymens.size
    @paymens = @paymens.order('created_at DESC').page(params[:page]).per(20)
    if client.plan == 4
      @paymens.each do |payment|
        # if payment.end_at >= Date.today
        bot_cv = Order.where(client_id: client.id).where('created_at >= ? AND created_at <= ?', payment.start_at, payment.end_at)
        payment.price = bot_cv.size * client.price
        # end
      end
    end
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
    params[:payment][:price] = params[:payment][:price] if params[:payment][:price].present?
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
    params.fetch(:payment, nil).permit(:client_id, :start_at, :end_at, :paid_at, :status, :price)
  end
end
