# frozen_string_literal: true

owner = User.find_by!(email: "client-admin@local.test")

design_settings = {
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
  title_bubble: "Local Demo Bot",
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

chatbot = Chatbot.find_or_initialize_by(user: owner, bot_name: "Local Demo Bot")
chatbot.assign_attributes(
  title: "Local Demo Bot",
  subtitle: "Seed chatbot for page checks",
  design_type: :flat,
  main_color: :blue,
  status: :on,
  chat_body_version: "2.0",
  design_settings: design_settings
)
chatbot.save!

UserChatbot.find_or_create_by!(user: owner, chatbot: chatbot) do |acl|
  acl.role = :bot_admin
end

reader = User.find_by!(email: "client@local.test")
UserChatbot.find_or_create_by!(user: reader, chatbot: chatbot) do |acl|
  acl.role = :reader
end

subuser_editor = User.find_by!(email: "subuser1@local.test")
UserChatbot.find_or_create_by!(user: subuser_editor, chatbot: chatbot) do |acl|
  acl.role = :editor
end

subuser_reader = User.find_by!(email: "subuser2@local.test")
UserChatbot.find_or_create_by!(user: subuser_reader, chatbot: chatbot) do |acl|
  acl.role = :reader
end
