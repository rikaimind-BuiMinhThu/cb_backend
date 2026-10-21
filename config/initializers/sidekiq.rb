Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
  config.logger = Rails.logger
end

Sidekiq.configure_server do |config|
  config.logger = Rails.logger
  config.redis = { url: ENV['REDIS_URL'] }
  Sidekiq::Scheduler.dynamic = true
  config.on(:startup) do
    DynamicSchedule.where(status: :active).each do |schedule|
      if schedule.cron.present?
        Sidekiq.set_schedule(schedule.name, { class: schedule.class_name,
                                              cron: schedule.cron.to_s,
                                              queue: schedule.priority,
                                              args: schedule.args })
      end
    end
    Sidekiq::Scheduler.reload_schedule!
  end
end
