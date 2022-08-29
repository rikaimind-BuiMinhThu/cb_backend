class RemoveMessageBagsFkFromConversions < ActiveRecord::Migration[7.0]
  def change
    if foreign_key_exists?(:conversions, :message_bag)
      remove_foreign_key :conversions, :message_bag
    end
  end
end
