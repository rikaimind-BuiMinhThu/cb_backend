class AddExecutionPolicyToScenarios < ActiveRecord::Migration[6.1]
  def up
    add_column :scenarios, :execution_policy, :integer, default: 0, null: false
    add_column :scenario_templates, :execution_policy, :integer, default: 0, null: false

    execute <<~SQL
      UPDATE scenarios SET execution_policy = 1 WHERE is_used_fukushashiki = TRUE
    SQL
    execute <<~SQL
      UPDATE scenario_templates SET execution_policy = 1 WHERE is_used_fukushashiki = TRUE
    SQL
  end

  def down
    remove_column :scenarios, :execution_policy
    remove_column :scenario_templates, :execution_policy
  end
end
