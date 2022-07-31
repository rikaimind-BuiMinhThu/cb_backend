class AddMessageBagToPayloadData < ActiveRecord::Migration[7.0]
  def change
    add_column :persistent_menus, :message_bag_id, :integer
    add_column :ice_breakers, :message_bag_id, :integer
    add_column :message_buttons, :message_bag_id, :integer
    remove_column :persistent_menus, :payload
    remove_column :ice_breakers, :answer
  end
end
