class AddTimerConfigToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :timer_config, :text
  end
end
