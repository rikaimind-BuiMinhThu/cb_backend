class CreateMessageBags < ActiveRecord::Migration[7.0]
  def change
    create_table :message_bags do |t|
      t.references :message_group, null: false, foreign_key: true
      t.string :bag_name

      t.timestamps
    end
  end
end
