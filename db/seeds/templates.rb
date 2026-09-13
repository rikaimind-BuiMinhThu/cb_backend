# frozen_string_literal: true

# Upsert global scenario + order-confirm templates.
# Loaded only by `rake templates:seed` (not by development db:seed).
#
#   bundle exec rake templates:seed

require Rails.root.join("db/seeds/templates/catalog.rb").to_s
require Rails.root.join("db/seeds/templates/conversation_builder.rb").to_s

admin_deel_id = User.admin_deel.order(:id).first&.id
builder = Seeds::Templates::ConversationBuilder.new
order_confirm_by_key = {}

Seeds::Templates::Catalog.order_confirm_rows.each do |row|
  record = OrderConfirmMessageTemplate.find_or_initialize_by(name: row[:name])
  record.created_by_id = record.created_by_id || admin_deel_id
  record.config_hash = row[:config]
  record.save!
  order_confirm_by_key[row[:key]] = row[:config]
  Rails.logger.info("Seeded OrderConfirmMessageTemplate #{record.id} #{record.name}")
end

Seeds::Templates::Catalog.scenario_rows.each do |row|
  order_confirm_config = order_confirm_by_key.fetch(row[:order_confirm_key])
  conversation = builder.build(row, order_confirm_config: order_confirm_config)

  record = ScenarioTemplate.find_or_initialize_by(name: row[:name])
  record.assign_attributes(
    created_by_id: record.created_by_id || admin_deel_id,
    scenario_type: "payment",
    conversation: JSON.generate(conversation),
    extra_config: JSON.generate(row[:extra_config]),
    landing_page_product_url: nil,
    merchandise_id: nil,
    is_used_crosssell: false,
    product_id_cross_sell: nil,
    is_used_custom_css: false,
    custom_css_content: nil,
    is_used_custom_js_code: false,
    head_custom_js_code: nil,
    top_body_custom_js_code: nil,
    bottom_body_custom_js_code: nil,
    is_used_err_msg_by_js: false,
    err_msg_js_code: nil
  )
  record.execution_policy = :fukushashiki
  record.sync_fukushashiki_from_execution_policy!
  record.save!
  Rails.logger.info("Seeded ScenarioTemplate #{record.id} #{record.name}")
end
