json.code 1
json.data @ice_breakers.each do |ice_breaker|
  json.merge! ice_breaker.as_json
  if ice_breaker.message_bag_id.present?
    json.message_bag_name ice_breaker.message_bag&.bag_name
    message_group = ice_breaker.message_bag&.message_group
    if message_group.present?
      json.message_group_id message_group.id
      json.message_group_name message_group.group_name
    end
  end
end
