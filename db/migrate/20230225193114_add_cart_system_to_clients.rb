class AddCartSystemToClients < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :cart_system, :integer, default: 0
  end
end
