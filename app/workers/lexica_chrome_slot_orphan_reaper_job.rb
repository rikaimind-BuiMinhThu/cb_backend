class LexicaChromeSlotOrphanReaperJob
  include Sidekiq::Worker
  sidekiq_options queue: :lexica, retry: 0

  STALE_AFTER = 2.minutes

  def perform
    scope = ScenarioUserResponseSeleniumResult.stale_queued(STALE_AFTER.ago)

    scope.find_each do |row|
      Rails.logger.info(
        "LexicaChromeSlotOrphanReaperJob recovering id=#{row.id} " \
        "scenario_id=#{row.scenario_id} user_input_id=#{row.user_input_id}"
      )
      LexicaScenarioJob.recover_chrome_slot_orphan!(row)
    end
  end
end
