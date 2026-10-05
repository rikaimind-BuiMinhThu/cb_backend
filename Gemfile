source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.2"

gem "rails", "~> 7.0.2", ">= 7.0.2.4"
gem "sprockets-rails"
gem "mysql2", "~> 0.5"
gem "puma", "~> 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "bootsnap", require: false
gem "dotenv-rails", require: "dotenv/rails-now"
gem "devise"
gem "jwt"
gem "config"
gem "ransack"
gem "omniauth-facebook"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "paranoia", "~> 2.6.0"
gem "rack-cors"
gem "kaminari"
gem "carrierwave", "~> 2.2.2"
gem "carrierwave-base64", "~> 2.10.0"
gem "aws-sdk-s3", "~> 1.117"
gem "selenium-webdriver", "4.8.1"
gem "socksify", "~> 1.7"
gem "colorize"
gem "google-cloud-speech", "~> 1.5"
gem "webdrivers", "5.2.0"
gem "webdriver-user-agent", "~> 7.3"
gem "redis"
gem "sidekiq"
gem 'whenever'
gem "sidekiq-scheduler"
gem 'rubocop', require: false
gem 'shopify_api'
gem "faraday"
gem "faraday-retry"
gem 'natto'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "byebug"
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "pry"
  gem "pry-rails"
  gem "awesome_print"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "letter_opener"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
end
