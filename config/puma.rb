# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma.

rails_env = ENV.fetch("RAILS_ENV") { "development" }
environment rails_env

if %w[staging production].include?(rails_env)
  # Clustered mode reconnects AR after fork. Do not load these on the
  # development `rails s` path (Puma would pull ActiveRecord in before Rails).
  require "erb"
  require "yaml"
  require "active_record"

  workers ENV.fetch("WEB_CONCURRENCY") { 2 }
  threads 1, 30

  app_dir = File.expand_path("../..", __FILE__)
  shared_dir = "#{app_dir}/shared"

  bind "unix://#{shared_dir}/sockets/puma.sock"
  stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true
  pidfile "#{shared_dir}/pids/puma.pid"
  state_path "#{shared_dir}/pids/puma.state"
  activate_control_app

  on_worker_boot do
    ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
    db = YAML.safe_load(ERB.new(File.read("#{app_dir}/config/database.yml")).result, aliases: true)
    ActiveRecord::Base.establish_connection(db[rails_env])
  end
else
  max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
  min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
  threads min_threads_count, max_threads_count

  worker_timeout 3600 if rails_env == "development"

  port ENV.fetch("PORT") { 3000 }
  pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }
  plugin :tmp_restart
end
