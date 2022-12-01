class AddDefaultToPaymentGateways < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_gateways, :is_default, :boolean, default: false
  end
end
