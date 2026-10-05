# frozen_string_literal: true

owner = User.find_by!(email: "client-admin@local.test")
client = Client.find_by!(name: "Local Dev")
chatbot = Chatbot.find_by!(user: owner, bot_name: "Local Demo Bot")
payment_scenario = Scenario.find_by!(chatbot: chatbot, name: "Local Payment Scenario")
faq_scenario = Scenario.find_by!(chatbot: chatbot, name: "Local FAQ Scenario")

[
  :pc,
  :smartphone,
  :pc_conversion,
  :smartphone_conversion,
  :smartphone_open_chatbot_window
].each_with_index do |analytic_type, index|
  analytic = AnalyticScenario.where(scenario: payment_scenario, type_of_analytic: analytic_type).first_or_initialize
  analytic.save! if analytic.new_record?
  analytic.update_columns(created_at: index.days.ago, updated_at: index.days.ago)
end

upsert_response = lambda do |scenario:, user_input_id:, data_input_name:, attrs:, created_at:|
  response = ScenarioUserResponse.find_or_initialize_by(
    scenario_id: scenario.id,
    user_input_id: user_input_id,
    data_input_name: data_input_name
  )
  response.assign_attributes(attrs)
  response.save!
  response.update_columns(created_at: created_at, updated_at: created_at)
  response
end

5.times do |index|
  user_input_id = "seed-user-input-#{format('%03d', index + 1)}"
  created_at = index.days.ago
  finished = index < 4

  scenario_user = ScenarioUser.find_or_initialize_by(
    scenario: payment_scenario,
    user_input_id: user_input_id
  )
  scenario_user.entry_count = index + 1
  scenario_user.save!
  scenario_user.update_columns(created_at: created_at, updated_at: created_at)

  upsert_response.call(
    scenario: payment_scenario,
    user_input_id: user_input_id,
    data_input_name: "user_name",
    attrs: {
      string_value: "Seed Visitor #{index + 1}",
      ui_type: "text_input",
      submit_type: :add,
      message_id: 2
    },
    created_at: created_at
  )

  upsert_response.call(
    scenario: payment_scenario,
    user_input_id: user_input_id,
    data_input_name: "user_name_kana",
    attrs: {
      string_value: "シードビジター#{index + 1}",
      ui_type: "text_input",
      submit_type: :add,
      message_id: 4
    },
    created_at: created_at
  )

  upsert_response.call(
    scenario: payment_scenario,
    user_input_id: user_input_id,
    data_input_name: "user_email",
    attrs: {
      string_value: "seed-visitor-#{index + 1}@example.com",
      ui_type: "text_input",
      submit_type: :add,
      message_id: 6
    },
    created_at: created_at
  )

  status = ScenarioUserResponseStatus.find_or_initialize_by(
    scenario_id: payment_scenario.id,
    user_input_id: user_input_id
  )
  status.status = finished ? :finished : :un_finished
  status.save!
  status.update_columns(created_at: created_at, updated_at: created_at)

  unless finished
    Order.where(
      client_id: client.id,
      scenario_id: payment_scenario.id,
      user_input_id: user_input_id
    ).delete_all
    next
  end

  upsert_response.call(
    scenario: payment_scenario,
    user_input_id: user_input_id,
    data_input_name: "password",
    attrs: {
      string_value: "SeedPass#{index + 1}!",
      ui_type: "text_input",
      submit_type: :add,
      message_id: 8
    },
    created_at: created_at
  )

  upsert_response.call(
    scenario: payment_scenario,
    user_input_id: user_input_id,
    data_input_name: "zip_code_address",
    attrs: {
      text_value: {
        post_code: "1500001",
        prefecture: "東京都",
        municipality: "渋谷区",
        address: "神宮前1-1-#{index + 1}",
        building_name: "Seed Building"
      }.to_json,
      ui_type: "zip_code_address",
      submit_type: :add,
      message_id: 10
    },
    created_at: created_at
  )

  upsert_response.call(
    scenario: payment_scenario,
    user_input_id: user_input_id,
    data_input_name: "phone_number",
    attrs: {
      string_value: "0901234567#{index}",
      ui_type: "text_input",
      submit_type: :add,
      message_id: 12
    },
    created_at: created_at
  )

  upsert_response.call(
    scenario: payment_scenario,
    user_input_id: user_input_id,
    data_input_name: "quantity",
    attrs: {
      string_value: (index + 1).to_s,
      integer_value: index + 1,
      ui_type: "text_input",
      submit_type: :add,
      message_id: 14
    },
    created_at: created_at
  )

  upsert_response.call(
    scenario: payment_scenario,
    user_input_id: user_input_id,
    data_input_name: "payment_method",
    attrs: {
      string_value: index.even? ? "credit_card" : "np_deferred",
      ui_type: "radio_button",
      submit_type: :add,
      message_id: 16
    },
    created_at: created_at
  )

  upsert_response.call(
    scenario: payment_scenario,
    user_input_id: user_input_id,
    data_input_name: "agree_term",
    attrs: {
      boolean_value: true,
      string_value: "true",
      ui_type: "agree_term",
      submit_type: :add,
      message_id: 20
    },
    created_at: created_at
  )

  [1, 2, 16, 20].each do |message_id|
    %i[appear add].each do |submit_type|
      message_log = ScenarioUserResponseMessage.find_or_initialize_by(
        scenario_id: payment_scenario.id,
        user_id: user_input_id,
        message_id: message_id,
        submit_type: submit_type
      )
      message_log.save! if message_log.new_record?
      message_log.update_columns(created_at: created_at, updated_at: created_at)
    end
  end

  if index.zero?
    error_log = ScenarioUserResponseMessage.find_or_initialize_by(
      scenario_id: payment_scenario.id,
      user_id: user_input_id,
      message_id: 6,
      submit_type: :error
    )
    error_log.save! if error_log.new_record?
    error_log.update_columns(created_at: created_at, updated_at: created_at)
  end

  order = Order.find_or_initialize_by(
    client_id: client.id,
    scenario_id: payment_scenario.id,
    user_input_id: user_input_id
  )
  order.bot_type = :web
  order.save!
  order.update_columns(created_at: created_at, updated_at: created_at)
end

2.times do |index|
  user_input_id = "seed-faq-user-#{format('%03d', index + 1)}"
  created_at = (index + 1).days.ago

  scenario_user = ScenarioUser.find_or_initialize_by(
    scenario: faq_scenario,
    user_input_id: user_input_id
  )
  scenario_user.entry_count = 1
  scenario_user.save!
  scenario_user.update_columns(created_at: created_at, updated_at: created_at)

  upsert_response.call(
    scenario: faq_scenario,
    user_input_id: user_input_id,
    data_input_name: "faq_question",
    attrs: {
      string_value: "配送料について教えてください（#{index + 1}）",
      ui_type: "text_input",
      submit_type: :add,
      message_id: 2
    },
    created_at: created_at
  )

  status = ScenarioUserResponseStatus.find_or_initialize_by(
    scenario_id: faq_scenario.id,
    user_input_id: user_input_id
  )
  status.status = :finished
  status.save!
  status.update_columns(created_at: created_at, updated_at: created_at)

  %i[appear add].each do |submit_type|
    message_log = ScenarioUserResponseMessage.find_or_initialize_by(
      scenario_id: faq_scenario.id,
      user_id: user_input_id,
      message_id: 2,
      submit_type: submit_type
    )
    message_log.save! if message_log.new_record?
    message_log.update_columns(created_at: created_at, updated_at: created_at)
  end
end

User.where(email: %w[admin@local.test client-admin@local.test client@local.test]).find_each.with_index do |user, index|
  next unless user.created_at > 2.days.ago

  user.update_columns(created_at: (index + 1).days.ago)
end
