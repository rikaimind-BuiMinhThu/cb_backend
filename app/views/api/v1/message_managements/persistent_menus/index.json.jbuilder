json.code 1
json.data @persistent_menus.each do |persistent_menu|
  json.merge! persistent_menu.as_json
  if persistent_menu.message_bag_id.present?
    json.message_bag_name persistent_menu.message_bag&.bag_name
    message_group = persistent_menu.message_bag&.message_group
    json.message_group_id message_group.id
    json.message_group_name message_group.group_name
  end
end
