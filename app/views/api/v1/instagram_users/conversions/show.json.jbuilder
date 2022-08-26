json.code 1
json.data @conversions.each do |conversion|
  json.merge! conversion.as_json
  json.conversion_at conversion.conversion_at
  json.message_bag_name conversion.message_bag.bag_name
  json.instagram_message_count @instagram_message_count
end
