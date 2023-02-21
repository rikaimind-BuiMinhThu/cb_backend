class AddDataInputNameToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :data_input_name, :string
  end
end
