json.code 1
json.data do
  json.instagram_users @instagram_users.each do |instagram_user|
    json.merge! instagram_user.as_json
    json.labels instagram_user.message_button_labels.pluck(:label_name)
  end
end
