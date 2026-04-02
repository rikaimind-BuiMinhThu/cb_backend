class AddShopifyFieldsToClients < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :shop_url, :string
    add_column :clients, :client_id, :string
    add_column :clients, :client_secret, :string
  end
end
