class AddTextValueToScenarioUserResponses < ActiveRecord::Migration[7.0]
  def change
    add_column :scenario_user_responses, :text_value, :text
  end
end
