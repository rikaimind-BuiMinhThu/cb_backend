# frozen_string_literal: true

namespace :chatbots do
  desc "Set every chatbot chat_body_version to 1.0 so existing LPs stay on the v1 body. Requires CONFIRM=yes"
  task backfill_body_version_1: :environment do
    abort "Refusing: set CONFIRM=yes to backfill chat_body_version to 1.0" unless ENV["CONFIRM"] == "yes"

    updated = Chatbot.where.not(chat_body_version: "1.0").update_all(chat_body_version: "1.0")
    counts = Chatbot.group(:chat_body_version).count
    puts "updated_rows=#{updated} counts=#{counts.inspect}"
  end
end
