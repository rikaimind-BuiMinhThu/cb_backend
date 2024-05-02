class DropProductUserProductVariantTables < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :variants, :products
    remove_foreign_key :user_products, :users
    remove_foreign_key :user_products, :products

    drop_table :products
    drop_table :user_products
    drop_table :variants
  end
end
