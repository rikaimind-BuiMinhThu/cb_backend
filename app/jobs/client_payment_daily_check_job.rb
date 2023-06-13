class ClientPaymentDailyCheckJob < ApplicationJob
  queue_as :default

  # job tự động gia hạn plan và thêm record payment history mới mỗi ngày vào lúc 0h sáng
  def perform
    begin
      clients = Client.where(status: 0)
      clients.each do |client|
        current_date = Date.current
        next_month = current_date + 1.month
        payment_histories = PaymentHistory.where('end_at >= ?', current_date)
        if payment_histories.empty? 
          PaymentHistory.create(
            client_id: client.id,
            start_at: current_date,
            end_at: next_month,
            price: client.plan == 4 ? 0 : client.price
          )
        end
      end
    rescue => e
      Log.error e.message
      Log.error e.backtrace.join("\n\t")
    end
  end
end
