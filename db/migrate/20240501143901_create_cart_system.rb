class CreateCartSystem < ActiveRecord::Migration[7.0]
  def change
    create_table :cart_systems do |t|
      t.references :user, foreign_key: true
      t.string :cart_token
      t.string :uid

      t.timestamps
    end
  end
end
