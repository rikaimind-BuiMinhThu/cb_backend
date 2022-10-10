class AddScenarioSelectedToChatbots < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :scenario_selected, :integer
  end
end
