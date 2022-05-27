class CreateClients < ActiveRecord::Migration[7.0]
  def change
    create_table :clients do |t|
      t.string :name
      t.string :address
      t.string :phone_number

      t.timestamps
    end

    add_index :clients, :name, unique: true

    add_foreign_key(
      :users,
      :clients,
      column: :client_id
    )
  end
end
