class CreateCustomItems < ActiveRecord::Migration[7.0]
  def change
    create_table :custom_items do |t|
      t.references :instagram_user, null: false, foreign_key: true
      t.string :title
      t.string :value

      t.timestamps
    end
  end
end
