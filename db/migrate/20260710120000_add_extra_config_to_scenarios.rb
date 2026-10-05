class AddExtraConfigToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :extra_config, :text
  end
end
