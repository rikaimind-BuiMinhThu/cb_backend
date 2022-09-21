class CreateChatbots < ActiveRecord::Migration[7.0]
  def change
    create_table :chatbots do |t|
      t.string :scenario
      t.string :title
      t.string :subtitle
      t.integer :design_type
      t.integer :main_color
      t.integer :status
      t.string :icon
      t.string :bot_name
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
