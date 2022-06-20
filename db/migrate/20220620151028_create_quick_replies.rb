class CreateQuickReplies < ActiveRecord::Migration[7.0]
  def change
    create_table :quick_replies do |t|
      t.references :message, null: false, foreign_key: true
      t.string :title

      t.timestamps
    end
  end
end
