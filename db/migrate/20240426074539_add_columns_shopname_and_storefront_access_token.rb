class AddColumnsShopnameAndStorefrontAccessToken < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :shop_name, :string
    add_column :users, :storefront_access_token, :string
  end
end
