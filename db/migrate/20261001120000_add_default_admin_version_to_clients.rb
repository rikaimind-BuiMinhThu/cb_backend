class AddDefaultAdminVersionToClients < ActiveRecord::Migration[7.0]
  def up
    return if column_exists?(:clients, :default_admin_version)

    # Existing rows pick up the column default "v1". New Client records
    # are set to "v2" in a before_create callback.
    add_column :clients, :default_admin_version, :string, null: false, default: "v1"
  end

  def down
    return unless column_exists?(:clients, :default_admin_version)

    remove_column :clients, :default_admin_version
  end
end
