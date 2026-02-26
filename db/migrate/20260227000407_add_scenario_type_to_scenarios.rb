class AddScenarioTypeToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :scenario_type, :string, default: 'payment'
    add_index :scenarios, :scenario_type
  end
end
