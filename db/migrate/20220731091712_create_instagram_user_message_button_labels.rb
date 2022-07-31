class CreateInstagramUserMessageButtonLabels < ActiveRecord::Migration[7.0]
  def change
    create_table :instagram_user_message_button_labels do |t|
      t.references :instagram_user, null: false, foreign_key: true
      t.references :message_button_labels, null: false, foreign_key: true

      t.timestamps
    end
  end
end
