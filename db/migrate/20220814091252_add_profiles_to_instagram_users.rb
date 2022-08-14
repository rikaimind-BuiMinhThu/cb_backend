class AddProfilesToInstagramUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :instagram_users, :real_name, :string
    add_column :instagram_users, :company_name, :string
    add_column :instagram_users, :company_role, :string
    add_column :instagram_users, :website, :string
    add_column :instagram_users, :propose, :string
    add_column :instagram_users, :know_product_in, :string
    add_column :instagram_users, :status, :integer
    add_column :instagram_users, :start_chatbot_in, :integer
    add_column :instagram_users, :start_chatbot_at, :datetime
  end
end
