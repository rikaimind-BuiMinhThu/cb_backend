json.code 1
json.data do
  json.extract! @town, :town_name, :town_name_kana, :zip_code
  if @town.present?
    city = City.find_by(city_jis_code: @town.city_jis_code)
    json.city_name city.city_name
    json.city_name_kane city.city_name_kana
    prefecture = Prefecture.find_by(prefecture_jis_code: @town.prefecture_jis_code)
    json.prefecture_name prefecture.name
    json.prefecture_name_kane prefecture.prefecture_name_kana
  end
end
