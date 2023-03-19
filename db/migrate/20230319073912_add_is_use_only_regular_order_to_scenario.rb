class AddIsUseOnlyRegularOrderToScenario < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :is_use_only_regular_order, :boolean, default: false
  end
end
