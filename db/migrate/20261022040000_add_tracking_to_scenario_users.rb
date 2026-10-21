class AddTrackingToScenarioUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :scenario_users, :device, :string
    add_column :scenario_users, :ip_address, :string
    add_column :scenario_users, :user_agent, :text
    add_column :scenario_users, :browser, :string
    add_column :scenario_users, :country, :string
    add_column :scenario_users, :city, :string
    add_column :scenario_users, :referer, :text
    add_column :scenario_users, :page_url, :text
  end
end
