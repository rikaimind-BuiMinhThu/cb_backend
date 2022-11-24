class AddPaymentToChatbot < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :include_tax, :boolean, default: false
    add_column :chatbots, :sale_tax_rate, :integer, default: 0
    add_column :chatbots, :calculate_one_yen, :boolean, default: false
    add_column :chatbots, :can_specify_payment, :boolean, default: false
    add_column :chatbots, :specify_payment_variable_id, :integer
    add_column :chatbots, :need_paid_settlement_fee, :boolean, default: false
    add_column :chatbots, :settlement_fee_variable_id, :integer
    add_column :chatbots, :need_paid_shipping_fee, :boolean, default: false
    add_column :chatbots, :shipping_fee_variable_id, :integer
    add_column :chatbots, :need_np_deferred_payment, :boolean, default: false
    add_column :chatbots, :np_invoice_included, :boolean, default: 0
    add_column :chatbots, :np_maximum_amount, :integer
    add_column :chatbots, :np_settlement_min_value, :integer
    add_column :chatbots, :np_settlement_max_value, :integer
    add_column :chatbots, :np_settlement_fee_value, :integer
  end
end
