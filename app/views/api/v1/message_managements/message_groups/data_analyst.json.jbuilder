json.code 1
json.data @message_groups do |message_group|
  json.merge! message_group.as_json
  json.client_name message_group&.user&.client&.name if current_user.admin_deel?
end
json.total @total
