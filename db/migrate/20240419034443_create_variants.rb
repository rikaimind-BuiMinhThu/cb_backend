class CreateVariants < ActiveRecord::Migration[7.0]
  def change
    create_table :variants do |t|
      t.bigint :cart_system_variant_id
      t.references :product, null: false, foreign_key: true
      t.string :name
      t.string :price

      t.timestamps
    end
  end
end
