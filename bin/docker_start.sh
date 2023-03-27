#!/bin/sh

if [ -f tmp/pids/server.pid ]; then
    rm tmp/pids/server.pid
fi

bundle install
rake db:create
rake db:migrate
rake db:seed

if [ "$RAILS_ENV" = "production" ]; then
    rake assets:precompile
    RAILS_ENV=$RAILS_ENV bundle exec puma -C config/puma.rb
else
    bundle exec rails s -b 0.0.0.0 -p 3000
fi
