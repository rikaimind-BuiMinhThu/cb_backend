class CreateNpValueSettlements < ActiveRecord::Migration[7.0]
  def change
    create_table :np_value_settlements do |t|
      t.integer :np_settlement_min_value
      t.integer :np_settlement_max_value
      t.integer :np_settlement_fee_value
      t.references :chatbot, null: false, foreign_key: true

      t.timestamps
    end
  end
end
