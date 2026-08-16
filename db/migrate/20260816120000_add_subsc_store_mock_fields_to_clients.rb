class AddSubscStoreMockFieldsToClients < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :is_use_mock_response, :boolean, default: false, null: false
    add_column :clients, :mock_response, :text
    add_column :clients, :extra_config, :text
  end
end
