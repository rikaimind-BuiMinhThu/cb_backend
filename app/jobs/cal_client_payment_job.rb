class CalClientPaymentJob < ApplicationJob
  queue_as :default
  
  # tạo payment history cho các client có sẵn
  def perform
    begin
      clients = Client.where(status: 0)
      clients.each do |client|
        payment_histories = PaymentHistory.where(client_id: client.id)
        if payment_histories.empty?
          current_date = client.subscription_start_at
          while current_date < Date.current
            next_month = current_date + 1.month
            price = client.price
            if client.plan == 4
              bot_cv = Order.where(client_id: client.id).where('created_at >= ? AND created_at <= ?', current_date, next_month)
              price = bot_cv.size * client.price
            end
            PaymentHistory.create(
              client_id: client.id,
              start_at: current_date,
              end_at: next_month,
              price: price
            )
            current_date = next_month + 1
          end
        end
      end
    rescue => e
      Log.error e.message
      Log.error e.backtrace.join("\n\t")
    end
  end
end
