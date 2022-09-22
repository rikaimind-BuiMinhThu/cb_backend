class CreateUserChatbots < ActiveRecord::Migration[7.0]
  def change
    create_table :user_chatbots do |t|
      t.references :user, null: false, foreign_key: true
      t.references :chatbot, null: false, foreign_key: true
      t.integer :role

      t.timestamps
    end
  end
end
