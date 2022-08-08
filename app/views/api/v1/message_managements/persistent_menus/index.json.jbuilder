json.code 1
json.data @persistent_menus.each do |persistent_menu|
  json.merge! persistent_menu.as_json
  message_bag = MessageBag.find_by(id: persistent_menu.message_bag_id) if persistent_menu.message_bag_id.present?
  json.message_bag_name message_bag&.bag_name if message_bag.present?
  json.message_group_name message_bag&.message_group&.group_name if message_bag.present?
end
