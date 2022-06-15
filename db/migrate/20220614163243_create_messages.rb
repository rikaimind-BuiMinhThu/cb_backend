class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.references :message_bag, null: false, foreign_key: true
      t.string :message_key
      t.string :message_value

      t.timestamps
    end
  end
end
