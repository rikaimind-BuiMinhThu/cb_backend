# frozen_string_literal: true

# Development dump-style seeds for local / Docker page checks.
#
# Docker:
#   cd EC-ChatBot-Backend
#   docker-compose up -d --build          # db:seed runs on container start
#   docker exec -it instagram_chatbot_api bundle exec rails db:seed
#
# Login:
#   admin@local.test / Password123!          (admin_deel)
#   client-admin@local.test / Password123!   (admin_client — owns bot / IG data)
#   client@local.test / Password123!         (client)

PaymentSystem.find_or_create_by!(name: "Shopify Payment")
PaymentSystem.find_or_create_by!(name: "SB Payment")

# Scenario / order-confirm templates are not part of this dump.
# Apply them with: bundle exec rake templates:seed

if Rails.env.development?
  Dir[Rails.root.join("db/seeds/*.rb")].sort.each do |seed_file|
    next if File.basename(seed_file) == "templates.rb"

    Rails.logger.info("Loading seed #{File.basename(seed_file)}")
    load seed_file
  end
end
