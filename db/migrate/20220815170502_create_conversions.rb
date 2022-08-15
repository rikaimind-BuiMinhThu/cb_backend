class CreateConversions < ActiveRecord::Migration[7.0]
  def change
    create_table :conversions do |t|
      t.references :instagram_user, null: false, foreign_key: true
      t.string :user_name
      t.integer :user_source
      t.datetime :conversion_at
      t.references :message_bag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
