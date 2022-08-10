class AddIsAdminAddToInstagramUserLabels < ActiveRecord::Migration[7.0]
  def change
    add_column :instagram_user_labels, :is_admin_add, :boolean, default: false
  end
end
