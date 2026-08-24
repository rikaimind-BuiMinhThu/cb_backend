module ScenarioExecutionPolicy
  extend ActiveSupport::Concern

  included do
    enum execution_policy: { rpa: 0, fukushashiki: 1, api: 2 }, _prefix: true
  end

  def sync_fukushashiki_from_execution_policy!
    self.is_used_fukushashiki = execution_policy_fukushashiki?
  end
end
