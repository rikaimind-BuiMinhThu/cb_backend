class CreatePushMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :push_messages do |t|
      t.string :title
      t.integer :sending_method
      t.references :chatbot, null: false, foreign_key: true
      t.references :email
      t.datetime :started_at
      t.boolean :has_timezone_exclusion, null: false, default: false
      t.integer :excluded_time_from
      t.integer :excluded_time_to
      t.integer :alternate_send_time
      t.boolean :subscribe_status, null: false, default: true
      t.integer :last_message_datetime_since

      t.timestamps
    end
  end
end
