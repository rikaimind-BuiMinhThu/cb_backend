class CreatePaymentHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_histories do |t|
      t.integer :client_id
      t.integer :status, default: 0, null: false
      t.datetime :start_at
      t.datetime :end_at
      t.datetime :paid_at

      t.timestamps
    end
  end
end
