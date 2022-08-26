class CreateChatbotUsageGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :chatbot_usage_groups do |t|
      t.references :chatbot_usage, null: false, foreign_key: true
      t.integer :message_group_id
      t.integer :message_bag_id

      t.timestamps
    end
  end
end
