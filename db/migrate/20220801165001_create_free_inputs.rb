class CreateFreeInputs < ActiveRecord::Migration[7.0]
  def change
    create_table :free_inputs do |t|
      t.references :message, null: false, foreign_key: true
      t.references :message_bag, null: false, foreign_key: true
      t.integer :format_check
      t.string :format_check_message

      t.timestamps
    end
  end
end
