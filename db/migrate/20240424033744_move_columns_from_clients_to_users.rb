class MoveColumnsFromClientsToUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :clients, :shopify_api_key, :string
    remove_column :clients, :cart_payment_system_id, :bigint

    add_column :users, :shopify_api_key, :string
    add_column :users, :cart_payment_system_id, :bigint
  end
end
