class PaymentHistory < ApplicationRecord
  validates :client_id, presence: true
  enum status: {unpaid: 0, paid: 1}

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "start_at", "id", "end_at", "status", "paid_at", "client_id"]
  end
end
