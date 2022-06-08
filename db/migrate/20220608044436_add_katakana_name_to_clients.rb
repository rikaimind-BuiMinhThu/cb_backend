class AddKatakanaNameToClients < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :name_katakana, :string
    add_column :clients, :responsible_person_katakana, :string
  end
end
