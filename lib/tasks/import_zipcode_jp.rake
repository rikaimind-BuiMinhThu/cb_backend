namespace :import_zipcode_jp do
  task prefecture: :environment do
    require 'json'

    filename = Dir.pwd + '/lib/data_zipcode_jp/prefecture.json'
    file = File.read(filename)
    data_hash = JSON.parse(file)

    data_hash.each do |prefecture|
      tmp = Prefecture.find_by(name: prefecture["prefecture_name"])
      if tmp.present?
        tmp.prefecture_jis_code = prefecture["prefecture_jis_code"]
        tmp.prefecture_name_kana = prefecture["prefecture_name_kana"]
        tmp.save
      end
    end
  end

  task city: :environment do
    Dir[Dir.pwd + "/lib/data_zipcode_jp/city/*.json"].each do |file_name|
      file = File.read(file_name)
      data_hash = JSON.parse(file)

      data_hash.each do |city|
        City.create(prefecture_jis_code: city["prefecture_jis_code"],
                    city_jis_code: city["city_jis_code"],
                    city_name: city["city_name"],
                    city_name_kana: city["city_name_kana"])
      end
    end
  end

  task town: :environment do
    Dir[Dir.pwd + "/lib/data_zipcode_jp/town/**/*.json"].each do |file_name|
      file = File.read(file_name)
      data_hash = JSON.parse(file)

      data_hash.each do |town|
        Town.create(prefecture_jis_code: town["prefecture_jis_code"],
                    city_jis_code: town["city_jis_code"],
                    town_name: town["town_name"],
                    town_name_kana: town["town_name_kana"],
                    zip_code: town["zip_code"])
      end
    end
  end

  task town_update: :environment do
    puts "run town update ..."
    Town.delete_all
    Dir[Dir.pwd + "/lib/data_zipcode_jp/zip_code/**/*.json"].each do |file_name|
      file = File.read(file_name)
      data_hash = JSON.parse(file)
      town = data_hash[0]

      Town.insert({prefecture_jis_code: town["prefecture_jis_code"],
                  city_jis_code: town["city_jis_code"],
                  town_name: town["town_name"],
                  town_name_kana: town["town_name_kana"],
                  zip_code: town["zip_code"]})
    end
    puts "done"
  end
end
