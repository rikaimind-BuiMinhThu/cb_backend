json.code 1
json.data @ice_breakers.each do |ice_breaker|
  json.merge! ice_breaker.as_json
  json.message_group_name MessageBag.find_by(id: ice_breaker.message_bag_id).message_group.group_name if ice_breaker.message_bag_id.present?
end
