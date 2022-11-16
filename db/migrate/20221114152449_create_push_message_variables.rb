class CreatePushMessageVariables < ActiveRecord::Migration[7.0]
  def change
    create_table :push_message_variables do |t|
      t.references :push_message, null: false, foreign_key: true
      t.references :variable, null: false, foreign_key: true
      t.integer :operator
      t.string :value

      t.timestamps
    end
  end
end
