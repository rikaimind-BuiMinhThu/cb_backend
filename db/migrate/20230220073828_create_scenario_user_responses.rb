class CreateScenarioUserResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :scenario_user_responses do |t|
      t.integer :scenario_id
      t.string :user_input_id
      t.string :string_value
      t.boolean :boolean_value
      t.integer :integer_value
      t.string :data_input_name

      t.timestamps
    end
  end
end
