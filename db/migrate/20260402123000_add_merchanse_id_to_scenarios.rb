class AddMerchanseIdToScenarios < ActiveRecord::Migration[6.0]
  def change
    add_column :scenarios, :merchandise_id, :string
  end
end
