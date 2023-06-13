class ClientPriceDailyCheckJob < ApplicationJob
  queue_as :default

  # job tự động tính toán chi phí phát sinh trong tháng đối với client.plan == 4, chạy vào 23:59 mỗi ngày
  def perform
    begin
      payment_histories = PaymentHistory.where(end_at: Date.current)
      payment_histories.each do |payment|
        client = Client.find_by(id: payment.client_id)
        price = client.price
        if client.plan == 4
          orders = Order.where(client_id: payment.client_id)
          price = orders.size * client.price
        end
        payment.price = price
        payment.update
      end
    rescue => e
      Log.error e.message
      Log.error e.backtrace.join("\n\t")
    end
  end
end
