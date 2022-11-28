class CreateSettlementFeeVariables < ActiveRecord::Migration[7.0]
  def change
    create_table :settlement_fee_variables do |t|
      t.string :variable_value
      t.integer :commission
      t.references :chatbot, null: false, foreign_key: true

      t.timestamps
    end
  end
end
