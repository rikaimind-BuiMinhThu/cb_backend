json.code 1
json.data do
  json.clients @clients.each do |client|
    json.merge! client.as_json
    json.last_sign_in_at client.users.admin_client.maximum(:last_sign_in_at)&.strftime("%Y/%m/%d %H:%M:%S")
  end
  json.total @total
end
