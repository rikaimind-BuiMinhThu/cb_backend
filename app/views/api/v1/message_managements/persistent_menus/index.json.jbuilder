json.code 1
json.data @persistent_menus do |persistent_menu|
  json.extract! persistent_menu, :id, :title, :message_bag_id, :url, :is_support, :instagram_account_id, :created_at, :updated_at
  if persistent_menu.message_bag_id.present?
    json.message_bag_name persistent_menu.message_bag&.bag_name
    message_group = persistent_menu.message_bag&.message_group
    if message_group.present?
      json.message_group_id message_group.id
      json.message_group_name message_group.group_name
    end
  end
end
