class CreateScenarioPages < ActiveRecord::Migration[7.0]
  def change
    create_table :scenario_pages do |t|
      t.references :scenario, null: false, foreign_key: true
      t.string :url
      t.integer :num_type

      t.timestamps
    end
  end
end
