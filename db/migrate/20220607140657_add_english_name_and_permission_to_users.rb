class AddEnglishNameAndPermissionToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :english_name, :string
    add_column :users, :can_read, :boolean, default: false
    add_column :users, :can_write, :boolean, default: false
    remove_index :clients, :name
  end
end
