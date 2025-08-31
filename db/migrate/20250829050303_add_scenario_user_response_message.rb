class AddScenarioUserResponseMessage < ActiveRecord::Migration[7.0]
  def change
    create_table :scenario_user_response_messages do |t|
      t.references :scenario, null: false, foreign_key: true
      t.integer :message_id, null: false
      t.string :user_id, null: false
      t.integer :submit_type, null: true

      t.timestamps
    end
  end
end
