class CreateChatbotUsages < ActiveRecord::Migration[7.0]
  def change
    create_table :chatbot_usages do |t|
      t.string :sender_id
      t.integer :usage_type
      t.string :content
      t.string :media_id
      t.datetime :media_start_at
      t.references :instagram_account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
