json.code 1
json.message "Success"
json.users @users do |user|
  json.extract! user, :id, :email, :full_name, :phone_number, :role, :client_id,
                      :english_name, :can_read, :can_write, :last_sign_in_at
end
json.total @total
