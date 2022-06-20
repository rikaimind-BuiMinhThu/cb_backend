class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.references :message_bag, null: false, foreign_key: true
      t.string :received_message
      t.string :message_value
      t.integer :message_type, default: 0

      t.timestamps
    end
  end
end
