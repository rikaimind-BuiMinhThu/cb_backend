class CreateSpecifyPaymentVariables < ActiveRecord::Migration[7.0]
  def change
    create_table :specify_payment_variables do |t|
      t.string :variable_value
      t.references :payment_gateway, null: false, foreign_key: true
      t.references :chatbot, null: false, foreign_key: true

      t.timestamps
    end
  end
end
