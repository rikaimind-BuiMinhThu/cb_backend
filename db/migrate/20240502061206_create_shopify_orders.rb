class CreateShopifyOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :shopify_orders do |t|
      t.references :cart_payment_system, null: false, foreign_key: true
      t.bigint :order_id

      t.timestamps
    end
  end
end
