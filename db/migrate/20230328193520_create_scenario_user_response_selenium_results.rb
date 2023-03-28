class CreateScenarioUserResponseSeleniumResults < ActiveRecord::Migration[7.0]
  def change
    create_table :scenario_user_response_selenium_results do |t|
      t.integer :client_id, null: false
      t.integer :chatbot_id, null: false
      t.integer :scenario_id, null: false
      t.string :user_input_id, null: false
      t.integer :last_step_no, null: false, default: 1
      t.string :last_step_description, null: true
      t.datetime :start_time
      t.datetime :end_time
      t.integer :result
      t.timestamps
    end
  end
end
