bundle install
rake db:drop
rake db:create
rake db:migrate
rake users_demo:run
rake message_demo:run
