class CreateShopifyConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :shopify_configs do |t|
      t.integer :scenario_id
      t.text :landing_page_product_url

      t.timestamps
    end
  end
end
