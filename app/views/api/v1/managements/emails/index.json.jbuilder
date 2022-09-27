json.code 1
json.data @emails.each do |email|
  json.merge! email.as_json
  json.cc email.email_ccs
  json.bcc email.email_bccs
end
json.total_count @emails.total_count
