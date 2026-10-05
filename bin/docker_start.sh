#!/bin/sh

mkdir -p tmp/pids tmp/docker-tmp tmp/docker-bundle

if [ -f tmp/pids/server.pid ]; then
    rm tmp/pids/server.pid
fi

flock tmp/bundle.lock bundle install
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed

if [ "$RAILS_ENV" = "production" ]; then
    rake assets:precompile
    RAILS_ENV=$RAILS_ENV bundle exec puma -C config/puma.rb
else
    bundle exec rails s -b 0.0.0.0 -p 3000
fi
