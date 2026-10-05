json.code 1
json.data @ice_breakers do |ice_breaker|
  json.extract! ice_breaker, :id, :question, :message_bag_id, :instagram_account_id, :created_at, :updated_at
  if ice_breaker.message_bag_id.present?
    json.message_bag_name ice_breaker.message_bag&.bag_name
    message_group = ice_breaker.message_bag&.message_group
    if message_group.present?
      json.message_group_id message_group.id
      json.message_group_name message_group.group_name
    end
  end
end
