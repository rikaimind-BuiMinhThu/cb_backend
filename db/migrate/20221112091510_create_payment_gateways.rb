class CreatePaymentGateways < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_gateways do |t|
      t.string :gateway_name
      t.integer :payment_agency
      t.integer :mode
      t.string :shop_id
      t.string :shop_pass
      t.string :merchant_code
      t.string :sp_code
      t.string :terminal_id
      t.string :client_ip
      t.string :store_id
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
