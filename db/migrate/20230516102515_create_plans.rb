class CreatePlans < ActiveRecord::Migration[7.0]
  def change
    create_table :plans do |t|
      t.string :name
      t.integer :code, unique: true
      t.text :description
      t.integer :price

      t.timestamps
    end
  end
end
