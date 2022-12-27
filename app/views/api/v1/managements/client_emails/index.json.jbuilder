json.code 1
json.data @client_emails.each do |client_email|
  json.id client_email.id
  json.email client_email.email
  json.client_id client_email.client.id
  json.full_name client_email.client.name
end
json.total @total
json.message "Success"
