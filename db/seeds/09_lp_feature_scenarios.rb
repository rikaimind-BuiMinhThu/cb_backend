# frozen_string_literal: true

# LP Feature Test Bot + 3 type-only UGC scenarios (IG / TT / RV)
# and LP Multi-3 Scenario (IG + TT + RV in one conversation).
# Idempotent. Does not change Local Demo Bot or Local UGC E2E Scenario.
#
# Staging:
#   LP_FEATURE_OWNER_EMAIL=... UGC_HOST=https://st.ugc-creative.com UGC_ENV=staging \
#     rails runner db/seeds/09_lp_feature_scenarios.rb

owner_email = ENV.fetch("LP_FEATURE_OWNER_EMAIL", "client-admin@local.test")
owner = User.find_by!(email: owner_email)
demo = Chatbot.find_by(user: owner, bot_name: "Local Demo Bot")

design_settings = if demo&.design_settings.present?
  demo.design_settings
else
  {
    display_type: 1,
    width_pc: 380,
    height_pc: 620,
    width_sp: 100,
    height_sp: 100,
    position_pc: 1,
    button_type_pc: 1,
    right_position_pc_title: "",
    right_margin_pc: 10,
    bottom_margin_pc: 10,
    position_sp: 1,
    button_type_sp: 1,
    right_position_sp_title: "",
    right_margin_sp: 10,
    bottom_margin_sp: 10,
    popup_close_bot: false,
    title_bubble: "LP Feature Test Bot",
    open_animation_duration_ms: 1000,
    open_animation_style: "slide_up",
    theme: {
      header_title_text_color: "#ffffff",
      header_title_font_size: "15px",
      header_subtitle_text_color: "#ffffff",
      header_subtitle_font_size: "14px",
      chat_window_bg_color: "#E8F1FF",
      bot_message_bg_color: "#327AED",
      bot_message_text_color: "#ffffff",
      bot_message_font_size: "14px",
      bot_message_border_style: "with_tail",
      user_message_bg_color: "#ffffff",
      user_message_text_color: "#333333",
      user_message_font_size: "14px",
      user_message_border_style: "no_tail",
      button_normal_bg_color: "#327AED",
      button_normal_text_color: "#ffffff",
      button_font_size: "14px",
      button_border_style: "rounded",
      button_effect: "none",
      button_position: "right"
    }
  }.to_json
end

lp_bot = Chatbot.find_or_initialize_by(user: owner, bot_name: "LP Feature Test Bot")
settings_json = design_settings
begin
  parsed = JSON.parse(settings_json)
  parsed["title_bubble"] = "LP Feature Test Bot"
  settings_json = parsed.to_json
rescue StandardError
  settings_json = design_settings
end
lp_bot.assign_attributes(
  title: "LP Feature Test Bot",
  subtitle: "Feature-test LP (IG / TT / RV)",
  design_type: :flat,
  main_color: :blue,
  status: :on,
  chat_body_version: "2.0",
  design_settings: settings_json
)
lp_bot.save!

opened_icon_files = []
%i[icon opening_bot_icon closing_bot_icon].each do |attribute|
  next if lp_bot.public_send(attribute).present?

  source = demo&.public_send(attribute)
  next if source.blank? || source.file.blank?

  path = source.path
  next if path.blank? || !File.exist?(path)

  file = File.open(path)
  opened_icon_files << file
  lp_bot.public_send("#{attribute}=", file)
end
if opened_icon_files.any?
  lp_bot.save!
  opened_icon_files.each(&:close)
end

UserChatbot.find_or_create_by!(user: owner, chatbot: lp_bot) do |acl|
  acl.role = :bot_admin
end

bot_text = lambda do |id, content|
  {
    id: id,
    hidden: false,
    belong_to: "bot",
    conditions: [],
    message_content: [
      {
        type: "text_input",
        text_input: {
          content: content,
          use_for_confirm_message: false
        },
        getting_error_notification: { use_for_confirm_message: false },
        email: {},
        file: {},
        script: {},
        html_code: {},
        delay: { typing_on: false },
        api_link_age: {},
        clear_variable: { variables: [] },
        variable_set: { variables: [] }
      }
    ]
  }
end

user_text_input = lambda do |id, attrs|
  {
    id: id,
    hidden: false,
    belong_to: "user",
    conditions: [],
    is_display_button_next: true,
    message_content: [
      {
        id: 1,
        type: "text_input",
        text_input: {
          title_require: true,
          title: attrs.fetch(:title),
          require: true,
          isUseConvertText: false,
          isCustomID: false,
          convertTextTypeValue: "katakana",
          idRefector: "",
          is_save_input_content: true,
          save_input_content: attrs.fetch(:save_input_content),
          type: "text",
          text: {
            range: "no_input",
            isSplitInput: false,
            placeholderLeft: attrs.fetch(:placeholder, attrs.fetch(:title))
          },
          urls: {},
          email_address: { placeholder: "email@example.com" },
          email_confirmation: {},
          phone_number: {
            withHyphen: false,
            disable_remove_leading_zero: false,
            number: "09012345678"
          },
          password: { password: "パスワード" },
          password_confirmation: {
            password: "パスワード",
            confirm_password: "確認用パスワード"
          }
        }
      }
    ]
  }
end

ugc_env = ENV.fetch("UGC_ENV", "local") == "staging" ? "staging" : "local"
ugc_host = ENV.fetch("UGC_HOST", "http://localhost:8080").sub(%r{/\z}, "")
ugc_samples_host = ENV.fetch("UGC_LOCAL_HOST", ugc_host).sub(%r{/\z}, "")
user_qid = Digest::SHA256.hexdigest("10ffwEn3Rgv_re")

samples = {}
begin
  require "net/http"
  require "json"
  uri = URI.parse("#{ugc_samples_host}/ugc/api/local-test/samples")
  res = Net::HTTP.get_response(uri)
  if res.is_a?(Net::HTTPSuccess)
    samples = JSON.parse(res.body)
  else
    Rails.logger.warn("LP feature seed: samples HTTP #{res.code} — run ugc:seed-lp-samples then re-run this seed")
  end
rescue StandardError => e
  Rails.logger.warn("LP feature seed: samples fetch failed (#{e.message}) — run ugc:seed-lp-samples then re-run this seed")
end

pick = lambda do |type, name|
  list = samples[type]
  return nil unless list.is_a?(Array)

  list.find { |row| row["name"] == name } || list.first
end

ig_row = pick.call("ig", "LP-LOCAL-IG") || pick.call("ig", "LP-UGC-IG-G1-slider-w1-s1")
tt_row = pick.call("tt", "LP-LOCAL-TT") || pick.call("tt", "LP-UGC-TT-G1-slider-w1-s1")
rv_row = pick.call("rv", "LP-LOCAL-RV") || pick.call("rv", "LP-UGC-RV-G1-in-chatbot")

ig_qid = ig_row && ig_row["qid"].present? ? ig_row["qid"] : "pending"
tt_qid = tt_row && tt_row["qid"].present? ? tt_row["qid"] : "pending"
rv_id = rv_row && rv_row["id"].present? ? rv_row["id"] : "pending"

if ig_qid == "pending" || tt_qid == "pending" || rv_id == "pending"
  puts "WARN: default UGC qids pending — run php artisan ugc:seed-lp-samples then re-run this seed"
end

html_config = lambda do |info_id, scripts|
  parts = [%(<input type="hidden" id="#{info_id}" data-host="#{ugc_host}">)]
  scripts.each { |src| parts << %(<script src="#{ugc_host}#{src}"></script>) }
  parts.join("\n")
end

iframe_html = lambda do |css_class, src|
  %(
<div class="#{css_class}-wrapper" style="overflow:hidden;width:100%;">
  <iframe class="#{css_class}" src="#{src}" style="width:100%;border:0;min-height:220px;display:block;"></iframe>
</div>
  ).gsub(/\s+/, " ").strip
end

conversation_for = lambda do |name, compare_text, config_html, iframe|
  {
    name: name,
    messages: [
      bot_text.call(1, compare_text),
      {
        id: 2,
        hidden: false,
        belong_to: "bot",
        conditions: [],
        message_content: [
          {
            type: "html_code",
            html_code: {
              content: iframe,
              use_for_ugc: true
            },
            getting_error_notification: { use_for_confirm_message: false },
            email: {},
            file: {},
            script: {},
            text_input: {},
            delay: { typing_on: false },
            api_link_age: {},
            clear_variable: { variables: [] },
            variable_set: { variables: [] }
          }
        ]
      },
      {
        id: 3,
        hidden: false,
        belong_to: "bot",
        conditions: [],
        message_content: [
          {
            type: "use_html_ugc_config",
            use_html_ugc_config: { content: config_html },
            getting_error_notification: { use_for_confirm_message: false },
            email: {},
            file: {},
            script: {},
            html_code: {},
            text_input: {},
            delay: { typing_on: false },
            api_link_age: {},
            clear_variable: { variables: [] },
            variable_set: { variables: [] }
          }
        ]
      },
      user_text_input.call(
        4,
        title: "LP continue",
        save_input_content: "lp_continue",
        placeholder: "LP continue"
      )
    ]
  }.to_json
end

ugc_bot_html = lambda do |id, iframe|
  {
    id: id,
    hidden: false,
    belong_to: "bot",
    conditions: [],
    message_content: [
      {
        type: "html_code",
        html_code: {
          content: iframe,
          use_for_ugc: true
        },
        getting_error_notification: { use_for_confirm_message: false },
        email: {},
        file: {},
        script: {},
        text_input: {},
        delay: { typing_on: false },
        api_link_age: {},
        clear_variable: { variables: [] },
        variable_set: { variables: [] }
      }
    ]
  }
end

ugc_config_message = lambda do |id, config_html|
  {
    id: id,
    hidden: false,
    belong_to: "bot",
    conditions: [],
    message_content: [
      {
        type: "use_html_ugc_config",
        use_html_ugc_config: { content: config_html },
        getting_error_notification: { use_for_confirm_message: false },
        email: {},
        file: {},
        script: {},
        html_code: {},
        text_input: {},
        delay: { typing_on: false },
        api_link_age: {},
        clear_variable: { variables: [] },
        variable_set: { variables: [] }
      }
    ]
  }
end

lp_page = ENV.fetch(
  "LP_FEATURE_PAGE",
  "#{ugc_host}/ugc/ugc-chatbot-feature-test.html"
)

specs = [
  {
    name: "LP IG Scenario",
    compare: "LP IG compare",
    flags: { is_ugc_instagram: true, is_ugc_tiktok: false, is_ugc_review: false },
    config: html_config.call("ugc-slider-info", [
      "/ugc/js/take.js",
      "/ugc/js/chatbot_ugc_modal_bridge.js",
      "/ugc/js/lp_feature_swap.js"
    ]),
    iframe: iframe_html.call("ugc-slider", "#{ugc_host}/ugc/api/slider?qid=#{ig_qid}&v=2&in_chatbot=1")
  },
  {
    name: "LP TT Scenario",
    compare: "LP TT compare",
    flags: { is_ugc_instagram: false, is_ugc_tiktok: true, is_ugc_review: false },
    config: html_config.call("ugc-tiktok-slider-info", [
      "/ugc/js/tiktoks/take.js",
      "/ugc/js/chatbot_ugc_modal_bridge.js",
      "/ugc/js/lp_feature_swap.js"
    ]),
    iframe: iframe_html.call("ugc-tiktok-slider", "#{ugc_host}/ugc/api/tiktok/slider?qid=#{tt_qid}&v=2&in_chatbot=1")
  },
  {
    name: "LP RV Scenario",
    compare: "LP RV compare",
    flags: { is_ugc_instagram: false, is_ugc_tiktok: false, is_ugc_review: true },
    config: html_config.call("ugc-review-slider-info", [
      "/ugc/js/api_reviews/take.js",
      "/ugc/js/lp_feature_swap.js"
    ]),
    iframe: iframe_html.call(
      "ugc-review-slider",
      "#{ugc_host}/ugc/api/reviews/embed?review_widget_id=#{rv_id}&user_id=10&user_qid=#{user_qid}&product_id=site&in_chatbot=1"
    )
  }
]

created = {}
specs.each do |spec|
  scenario = Scenario.find_or_initialize_by(chatbot: lp_bot, name: spec[:name])
  scenario.assign_attributes(
    {
      scenario_type: "faq",
      conversation: conversation_for.call(spec[:name], spec[:compare], spec[:config], spec[:iframe]),
      is_used_html_ugc: true,
      ugc_env: ugc_env,
      html_ugc_config_content: spec[:config]
    }.merge(spec[:flags])
  )
  scenario.save!
  ScenarioPage.find_or_create_by!(scenario: scenario, url: lp_page) do |page|
    page.num_type = :num_of_start
  end
  created[spec[:name]] = scenario.id
end

multi3_name = "LP Multi-3 Scenario"
multi3_config = [
  html_config.call("ugc-slider-info", ["/ugc/js/take.js"]),
  html_config.call("ugc-tiktok-slider-info", ["/ugc/js/tiktoks/take.js"]),
  %(<script src="#{ugc_host}/ugc/js/chatbot_ugc_modal_bridge.js"></script>),
  html_config.call("ugc-review-slider-info", ["/ugc/js/api_reviews/take.js"])
].join("\n")

multi3 = Scenario.find_or_initialize_by(chatbot: lp_bot, name: multi3_name)
multi3.assign_attributes(
  scenario_type: "faq",
  conversation: {
    name: multi3_name,
    messages: [
      bot_text.call(1, "LP multi 3 compare"),
      ugc_bot_html.call(2, iframe_html.call("ugc-slider", "#{ugc_host}/ugc/api/slider?qid=#{ig_qid}&v=2&in_chatbot=1")),
      ugc_bot_html.call(3, iframe_html.call("ugc-tiktok-slider", "#{ugc_host}/ugc/api/tiktok/slider?qid=#{tt_qid}&v=2&in_chatbot=1")),
      ugc_bot_html.call(
        4,
        iframe_html.call(
          "ugc-review-slider",
          "#{ugc_host}/ugc/api/reviews/embed?review_widget_id=#{rv_id}&user_id=10&user_qid=#{user_qid}&product_id=site&in_chatbot=1"
        )
      ),
      ugc_config_message.call(5, multi3_config),
      user_text_input.call(
        6,
        title: "LP continue",
        save_input_content: "lp_continue",
        placeholder: "LP continue"
      )
    ]
  }.to_json,
  is_used_html_ugc: true,
  is_ugc_instagram: true,
  is_ugc_tiktok: true,
  is_ugc_review: true,
  ugc_env: ugc_env,
  html_ugc_config_content: multi3_config
)
multi3.save!
ScenarioPage.find_or_create_by!(scenario: multi3, url: lp_page) do |page|
  page.num_type = :num_of_start
end
created[multi3_name] = multi3.id

ig_scenario = Scenario.find_by!(chatbot: lp_bot, name: "LP IG Scenario")
lp_bot.update!(scenario_selected: ig_scenario.id)

puts "LP Feature Test Bot id=#{lp_bot.id}"
puts "LP IG Scenario id=#{created['LP IG Scenario']}"
puts "LP TT Scenario id=#{created['LP TT Scenario']}"
puts "LP RV Scenario id=#{created['LP RV Scenario']}"
puts "LP Multi-3 Scenario id=#{created['LP Multi-3 Scenario']}"
puts "UGC_ENV=#{ugc_env} UGC_HOST=#{ugc_host} owner=#{owner_email}"
puts "Next: php artisan ugc:set-lp-chatbot-ids --env=#{ugc_env} --bot=#{lp_bot.id} --ig=#{created['LP IG Scenario']} --tt=#{created['LP TT Scenario']} --rv=#{created['LP RV Scenario']} --multi3=#{created['LP Multi-3 Scenario']}"
