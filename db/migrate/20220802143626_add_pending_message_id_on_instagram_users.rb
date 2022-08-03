class AddPendingMessageIdOnInstagramUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :instagram_users, :pending_message_id, :integer
    add_column :instagram_users, :email, :string
    add_column :instagram_users, :phone_number, :string
  end
end
