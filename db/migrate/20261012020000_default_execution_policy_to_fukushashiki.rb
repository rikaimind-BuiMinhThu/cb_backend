class DefaultExecutionPolicyToFukushashiki < ActiveRecord::Migration[6.1]
  def up
    change_column_default :scenarios, :execution_policy, from: 0, to: 1
    change_column_default :scenario_templates, :execution_policy, from: 0, to: 1
  end

  def down
    change_column_default :scenarios, :execution_policy, from: 1, to: 0
    change_column_default :scenario_templates, :execution_policy, from: 1, to: 0
  end
end
