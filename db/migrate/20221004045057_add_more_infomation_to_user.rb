class AddMoreInfomationToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :business_division, :string
    add_column :users, :company_name, :string
    add_column :users, :department, :string
    add_column :users, :job_title, :string
    add_column :users, :post_code, :string
    add_column :users, :address, :string
    add_column :users, :language, :string
  end
end
