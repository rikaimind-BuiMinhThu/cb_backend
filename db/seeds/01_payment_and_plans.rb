# frozen_string_literal: true

[
  { name: "Starter", code: 1, price: 0, description: "Local seed starter plan" },
  { name: "Standard", code: 2, price: 9800, description: "Local seed standard plan" },
  { name: "Premium", code: 3, price: 29800, description: "Local seed premium plan" }
].each do |attrs|
  plan = Plan.find_or_initialize_by(code: attrs[:code])
  plan.name = attrs[:name]
  plan.price = attrs[:price]
  plan.description = attrs[:description]
  plan.save!
end
