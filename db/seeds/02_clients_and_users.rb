# frozen_string_literal: true

seed_password = "Password123!"

local_client = Client.find_or_initialize_by(name: "Local Dev")
local_client.assign_attributes(
  status: :active,
  is_web: true,
  is_instagram: true,
  is_line: false,
  is_tiktok: false,
  cart_system: :tamago_repeat,
  unit_price_web: 100,
  plan: 2,
  price: 9800,
  phone_number: "0312345678",
  address: "東京都渋谷区1-1-1",
  note: "Primary local development client"
)
local_client.save!

[
  { name: "Demo Client Alpha", plan: 1, price: 0 },
  { name: "Demo Client Beta", plan: 3, price: 29800 },
  { name: "Demo Client Gamma", plan: 2, price: 9800 }
].each do |attrs|
  client = Client.find_or_initialize_by(name: attrs[:name])
  client.assign_attributes(
    status: :active,
    is_web: true,
    is_instagram: true,
    plan: attrs[:plan],
    price: attrs[:price],
    phone_number: "09011112222",
    address: "大阪府大阪市1-2-3",
    note: "Extra seed client for list pages"
  )
  client.save!
end

[
  { email: "admin@local.test", role: :admin_deel, full_name: "Local Admin", client: local_client },
  { email: "client-admin@local.test", role: :admin_client, full_name: "Local Client Admin", client: local_client },
  { email: "client@local.test", role: :client, full_name: "Local Client User", client: local_client },
  { email: "subuser1@local.test", role: :client, full_name: "Local Sub User 1", client: local_client },
  { email: "subuser2@local.test", role: :client, full_name: "Local Sub User 2", client: local_client },
  { email: "alpha-admin@local.test", role: :admin_client, full_name: "Alpha Admin", client: Client.find_by!(name: "Demo Client Alpha") }
].each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.client = attrs[:client]
  user.role = attrs[:role]
  user.full_name = attrs[:full_name]
  user.phone_number = "00000000000"
  user.can_read = true
  user.can_write = true
  user.password = seed_password
  user.password_confirmation = seed_password
  user.save!
end
