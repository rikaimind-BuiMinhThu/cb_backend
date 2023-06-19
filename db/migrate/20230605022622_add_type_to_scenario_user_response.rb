class AddTypeToScenarioUserResponse < ActiveRecord::Migration[7.0]
  def change
    add_column :scenario_user_responses, :ui_type, :string
    add_column :scenario_user_responses, :message_id, :integer
  end
end
