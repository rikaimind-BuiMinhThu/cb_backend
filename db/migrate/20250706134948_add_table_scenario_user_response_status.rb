class AddTableScenarioUserResponseStatus < ActiveRecord::Migration[7.0]
  def change
    create_table :scenario_user_response_statuses do |t|
      t.integer :scenario_id
      t.string :user_input_id
      t.integer :status

      t.timestamps
    end
  end
end
