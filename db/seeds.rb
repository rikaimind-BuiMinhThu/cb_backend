# frozen_string_literal: true

PaymentSystem.find_or_create_by!(name: "Shopify Payment")
PaymentSystem.find_or_create_by!(name: "SB Payment")

if Rails.env.development?
  local_client = Client.find_or_create_by!(name: "Local Dev")
  local_client.update!(status: :active, is_web: true, is_instagram: true)

  local_users = [
    { email: "admin@local.test", role: :admin_deel, full_name: "Local Admin" },
    { email: "client-admin@local.test", role: :admin_client, full_name: "Local Client Admin" },
    { email: "client@local.test", role: :client, full_name: "Local Client User" }
  ]

  local_password = "Password123!"

  local_users.each do |attrs|
    user = User.find_or_initialize_by(email: attrs[:email])
    user.client = local_client
    user.role = attrs[:role]
    user.full_name = attrs[:full_name]
    user.phone_number = "00000000000"
    user.can_read = true
    user.can_write = true
    user.password = local_password
    user.password_confirmation = local_password
    user.save!
  end
end
