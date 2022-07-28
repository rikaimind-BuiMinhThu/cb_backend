class CreateMessageButtons < ActiveRecord::Migration[7.0]
  def change
    create_table :message_buttons do |t|
      t.references :message, null: false, foreign_key: true
      t.integer :button_type
      t.string :title
      t.string :content

      t.timestamps
    end
  end
end
