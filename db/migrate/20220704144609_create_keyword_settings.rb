class CreateKeywordSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :keyword_settings do |t|
      t.string :title
      t.string :keyword
      t.references :instagram_account, null: false, foreign_key: true
      t.boolean :is_dm, null: false, default: false
      t.boolean :is_story_comment, null: false, default: false
      t.boolean :is_post_comment, null: false, default: false
      t.boolean :is_live_comment, null: false, default: false
      t.references :message_bag, null: false, foreign_key: true
      t.boolean :is_active

      t.timestamps
    end
  end
end
