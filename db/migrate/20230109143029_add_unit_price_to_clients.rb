class AddUnitPriceToClients < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :unit_price_instagram, :integer
    add_column :clients, :unit_price_web, :integer
    add_column :clients, :unit_price_line, :integer
    add_column :clients, :unit_price_tiktok, :integer
  end
end
