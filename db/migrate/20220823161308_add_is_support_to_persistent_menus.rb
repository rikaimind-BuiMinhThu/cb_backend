class AddIsSupportToPersistentMenus < ActiveRecord::Migration[7.0]
  def change
    add_column :persistent_menus, :is_support, :boolean, default: false
  end
end
