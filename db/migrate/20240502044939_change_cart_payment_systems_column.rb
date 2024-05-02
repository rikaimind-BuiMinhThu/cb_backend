class ChangeCartPaymentSystemsColumn < ActiveRecord::Migration[7.0]
  def change
    add_column :cart_payment_systems, :cart_system_ids, :bigint, array: true, default: []

    remove_column :cart_payment_systems, :cart_system_id
  end
end
