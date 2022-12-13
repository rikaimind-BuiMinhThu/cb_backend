class CreateAnalyticScenarios < ActiveRecord::Migration[7.0]
  def change
    create_table :analytic_scenarios do |t|
      t.integer :type_of_analytic
      t.references :scenario, null: false, foreign_key: true

      t.timestamps
    end
  end
end
