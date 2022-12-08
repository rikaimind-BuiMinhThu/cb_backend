class CreateCities < ActiveRecord::Migration[7.0]
  def change
    create_table :cities do |t|
      t.string :prefecture_jis_code
      t.string :city_jis_code
      t.string :city_name
      t.string :city_name_kana

      t.timestamps
    end

    add_index :cities, :prefecture_jis_code
    add_index :cities, :city_jis_code
  end
end
