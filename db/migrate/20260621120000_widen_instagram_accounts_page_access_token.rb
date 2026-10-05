class WidenInstagramAccountsPageAccessToken < ActiveRecord::Migration[7.0]
  def up
    change_column :instagram_accounts, :page_access_token, :text
  end

  def down
    change_column :instagram_accounts, :page_access_token, :string
  end
end
