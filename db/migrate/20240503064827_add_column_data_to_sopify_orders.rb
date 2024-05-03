class AddColumnDataToSopifyOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :shopify_orders, :data, :json
  end
end
