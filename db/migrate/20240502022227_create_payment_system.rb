class CreatePaymentSystem < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_systems do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
