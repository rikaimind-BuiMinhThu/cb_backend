json.code 1
json.data do @conversions.each do |conversion|
  json.merge! conversion.as_json
  json.conversion_at conversion.conversion_at
  json.message_bag_name conversion.message_bag.bag_name
end
