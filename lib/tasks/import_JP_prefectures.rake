namespace :import_JP_prefectures do
  task run: :environment do
    require 'csv'

    filename = Dir.pwd + '/lib/assets/JP_prefectures.csv'
    CSV.foreach(filename, quote_char: '"', col_sep: ';', row_sep: :auto, headers: false) do |row|
      Prefecture.create!(name: row[0])
    end
  end
end
