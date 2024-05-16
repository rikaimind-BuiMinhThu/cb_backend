class AddShopifyApiKeyAndCartPaymentSystemIdToClients < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :shopify_api_key, :string
    add_column :clients, :cart_payment_system_id, :bigint
  end
end
