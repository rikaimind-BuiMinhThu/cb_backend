class CreateTowns < ActiveRecord::Migration[7.0]
  def change
    create_table :towns do |t|
      t.string :prefecture_jis_code
      t.string :city_jis_code
      t.string :town_name
      t.string :town_name_kana
      t.string :zip_code

      t.timestamps
    end

    add_index :towns, :prefecture_jis_code
    add_index :towns, :city_jis_code
  end
end
