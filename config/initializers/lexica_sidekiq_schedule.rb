Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq.set_schedule(
      "lexica_chrome_slot_orphan_reaper",
      {
        class: "LexicaChromeSlotOrphanReaperJob",
        cron: "* * * * *",
        queue: "lexica"
      }
    )
    Sidekiq::Scheduler.reload_schedule!
  end
end
