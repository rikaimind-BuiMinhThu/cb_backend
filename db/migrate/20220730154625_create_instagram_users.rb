class CreateInstagramUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :instagram_users do |t|
      t.string :instagram_id
      t.string :username
      t.string :full_name
      t.integer :follower_count
      t.boolean :is_verified_user
      t.boolean :is_user_follow_business
      t.boolean :is_business_follow_user
      t.references :instagram_account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
