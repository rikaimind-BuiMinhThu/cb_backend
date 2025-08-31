class AddScenarioUser < ActiveRecord::Migration[7.0]
  def change
    create_table :scenario_users do |t|
      t.references :scenario, null: false, foreign_key: true
      t.string :user_input_id, null: false
      t.integer :entry_count, default: 0

      t.timestamps
    end
  end
end
