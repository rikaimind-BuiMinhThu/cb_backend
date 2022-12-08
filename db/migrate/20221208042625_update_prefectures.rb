class UpdatePrefectures < ActiveRecord::Migration[7.0]
  def change
    add_column :prefectures, :prefecture_jis_code, :string
    add_column :prefectures, :prefecture_name_kana, :string

    add_index :prefectures, :prefecture_jis_code
  end
end
