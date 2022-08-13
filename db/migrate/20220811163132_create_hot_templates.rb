class CreateHotTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :hot_templates do |t|
      t.string :title
      t.string :description
      t.references :message_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
