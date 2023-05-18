Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
  config.logger = Rails.logger
end

Sidekiq.configure_server do |config|
  config.logger = Rails.logger
end
