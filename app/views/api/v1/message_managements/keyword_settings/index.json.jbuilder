json.code 1
json.data @keywords.each do |keyword|
  json.merge! keyword.as_json
  json.message_group_name keyword.message_bag.message_group.group_name
end
