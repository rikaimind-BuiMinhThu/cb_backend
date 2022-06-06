class AddInfoToClients < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :status, :integer
    add_column :clients, :plan, :integer
    add_column :clients, :price, :integer
    add_column :clients, :subscription_start_at, :datetime
    add_column :clients, :subscription_end_at, :datetime
    add_column :clients, :is_instagram, :boolean, default: false
    add_column :clients, :is_line, :boolean, default: false
    add_column :clients, :is_tiktok, :boolean, default: false
    add_column :clients, :is_web, :boolean, default: false
    add_column :clients, :note, :text
    add_column :clients, :enterprise_type, :string
    add_column :clients, :enterprise_type_2, :string
    add_column :clients, :department_name, :string
    add_column :clients, :title, :string
    add_column :clients, :responsible_person, :string
    add_column :clients, :logo_url, :string
    add_column :clients, :url, :string
    add_column :clients, :zip_code, :string
    add_column :clients, :prefecture, :string
    add_column :clients, :municipality, :string
    add_column :clients, :building_name, :string
    add_column :clients, :email, :string
  end
end
