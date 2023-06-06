class AddTypeToScenarioUserResponse < ActiveRecord::Migration[7.0]
  def change
    add_column :scenario_user_responses, :ui_type, :string
  end
end
