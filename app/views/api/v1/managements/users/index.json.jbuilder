json.code 1
json.message "Success"
json.users @users do |user|
  json.extract! user, :id, :email, :full_name, :phone_number, :role, :client_id,
                      :english_name, :can_read, :can_write, :last_sign_in_at,
                      :business_division, :company_name, :department, :job_title,
                      :post_code, :address, :language, :url
  json.full_name user.client.name if user.admin_client?
  json.client_name user&.client&.name
end
json.total @total
