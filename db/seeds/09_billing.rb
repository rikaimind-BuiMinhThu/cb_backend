# frozen_string_literal: true

client = Client.find_by!(name: "Local Dev")

[
  { status: :paid, price: 9800, days_ago: 30 },
  { status: :paid, price: 9800, days_ago: 60 },
  { status: :unpaid, price: 9800, days_ago: 0 }
].each_with_index do |attrs, index|
  start_at = attrs[:days_ago].days.ago.beginning_of_day
  end_at = start_at + 30.days

  history = PaymentHistory.find_or_initialize_by(
    client_id: client.id,
    start_at: start_at,
    end_at: end_at
  )
  history.status = attrs[:status]
  history.price = attrs[:price]
  history.paid_at = attrs[:status] == :paid ? start_at + 1.day : nil
  history.save!
end
