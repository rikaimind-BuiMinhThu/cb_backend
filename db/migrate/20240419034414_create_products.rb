class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :name
      t.string :image
      t.bigint :cart_system_product_id

      t.timestamps
    end
  end
end
