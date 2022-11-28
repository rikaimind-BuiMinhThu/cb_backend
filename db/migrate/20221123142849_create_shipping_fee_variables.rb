class CreateShippingFeeVariables < ActiveRecord::Migration[7.0]
  def change
    create_table :shipping_fee_variables do |t|
      t.references :prefecture, null: false, foreign_key: true
      t.integer :amount
      t.references :chatbot, null: false, foreign_key: true

      t.timestamps
    end
  end
end
