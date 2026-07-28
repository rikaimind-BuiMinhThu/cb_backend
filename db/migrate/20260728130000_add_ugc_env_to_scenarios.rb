class AddUgcEnvToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :ugc_env, :string, default: 'staging', null: false
  end
end
