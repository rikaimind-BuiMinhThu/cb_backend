class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.references :client, null: false, foreign_key: true
      t.integer :scenario_id, :null => false
      t.integer :bot_type, :null => false
      t.string :user_input_id, :null => false

      t.timestamps
    end
  end
end
