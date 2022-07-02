class CreateInstagramAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :instagram_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ig_id
      t.string :page_id
      t.string :fb_user_id
      t.string :page_access_token
      t.boolean :status, default: false
      t.integer :dm_bag_id
      t.boolean :dm_bag_status, null: false, default: false
      t.integer :post_comment_bag_id
      t.boolean :post_comment_bag_status, null: false, default: false
      t.integer :story_comment_bag_id
      t.boolean :story_comment_bag_status, null: false, default: false
      t.integer :live_comment_bag_id
      t.boolean :live_comment_bag_status, null: false, default: false

      t.timestamps
    end

    add_index :instagram_accounts, :ig_id, unique: true
  end
end
