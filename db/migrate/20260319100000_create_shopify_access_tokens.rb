class CreateShopifyAccessTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :shopify_access_tokens do |t|
      t.references :client, null: false, foreign_key: true
      t.text :admin_token
      t.text :storefront_token
      t.integer :expires_in
      t.datetime :issued_at
      t.datetime :expires_at
      t.timestamps
    end
  end
end
