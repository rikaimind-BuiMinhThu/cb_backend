class CreateMessageGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :message_groups do |t|
      t.string :group_name

      t.timestamps
    end
  end
end
