class AddCrosssellFieldsToScenarios < ActiveRecord::Migration[6.0]
  def change
    add_column :scenarios, :is_used_crosssell, :boolean, default: false, null: false
    add_column :scenarios, :product_id_cross_sell, :string
  end
end
