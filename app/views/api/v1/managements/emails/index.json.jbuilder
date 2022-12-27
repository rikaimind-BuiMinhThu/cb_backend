json.code 1
json.data @emails.each do |email|
  json.merge! email.as_json
  json.cc email.email_ccs
  json.bcc email.email_bccs
end
json.total @total
json.client_email @chatbot&.user&.client&.client_email&.email
