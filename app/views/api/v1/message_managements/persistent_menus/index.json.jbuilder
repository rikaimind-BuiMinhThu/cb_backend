json.code 1
json.data @persistent_menus.each do |persistent_menu|
  json.merge! persistent_menu.as_json
  json.message_group_name MessageBag.find_by(id: persistent_menu.message_bag_id)&.message_group&.group_name if persistent_menu.message_bag_id.present?
end
