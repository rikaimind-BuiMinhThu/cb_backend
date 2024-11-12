class AddUsedFukushashikiToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :is_used_fukushashiki, :boolean, default: false
  end
end
