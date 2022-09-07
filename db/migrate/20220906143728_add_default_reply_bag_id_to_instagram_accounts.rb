class AddDefaultReplyBagIdToInstagramAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :instagram_accounts, :default_reply_bag_id, :integer
  end
end
