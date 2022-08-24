class ChangeInstagramUserInSupportingUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :supporting_users, :sender_id
    add_reference :supporting_users, :instagram_user, index: true
  end
end
