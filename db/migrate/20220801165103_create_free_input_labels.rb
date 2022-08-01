class CreateFreeInputLabels < ActiveRecord::Migration[7.0]
  def change
    create_table :free_input_labels do |t|
      t.references :free_input, null: false, foreign_key: true
      t.string :label_name

      t.timestamps
    end
  end
end
