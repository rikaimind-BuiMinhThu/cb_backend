class AddFieldsForConversionToScenarioUserResponse < ActiveRecord::Migration[7.0]
  def change
    change_table :scenario_user_responses do |t|
      t.integer :submit_type, default: 1, null: true
      t.integer :message_child_id, default: -1, null: true
    end
  end
end
