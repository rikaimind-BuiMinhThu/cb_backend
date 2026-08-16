class AddSubscStoreApiFields < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :order_execution_mode, :integer, default: 3, null: false
    add_column :scenarios, :order_execution_mode, :integer
    add_column :scenarios, :extra_config, :text
    add_column :orders, :external_order_id, :string
    add_column :orders, :external_order_uid, :string
  end
end
