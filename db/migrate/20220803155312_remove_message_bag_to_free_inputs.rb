class RemoveMessageBagToFreeInputs < ActiveRecord::Migration[7.0]
  def change
    remove_column :free_inputs, :message_bag_id
  end
end
