class CreateMessageButtonLabels < ActiveRecord::Migration[7.0]
  def change
    create_table :message_button_labels do |t|
      t.references :message_button, null: false, foreign_key: true
      t.string :label_name

      t.timestamps
    end
  end
end
