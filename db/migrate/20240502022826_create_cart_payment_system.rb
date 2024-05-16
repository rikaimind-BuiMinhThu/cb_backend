class CreateCartPaymentSystem < ActiveRecord::Migration[7.0]
  def change
    create_table :cart_payment_systems do |t|
      t.references :cart_system, foreign_key: true, null: false
      t.references :payment_system, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end
  end
end
