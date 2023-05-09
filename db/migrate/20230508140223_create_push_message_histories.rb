class CreatePushMessageHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :push_message_histories do |t|
      t.datetime :sent_time
      t.string :destination
      t.integer :sending_method
      t.integer :number_of_failed_transmissions
      t.integer :status

      t.integer :scenario_id
      t.string :user_input_id

      t.string :response_data

      t.references :push_message, null: false
      t.references :chatbot, null: false, foreign_key: true

      t.timestamps
    end
  end
end
