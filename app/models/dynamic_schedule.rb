class DynamicSchedule < ApplicationRecord
  enum status: { inactive: false, active: true }, _prefix: :status
  enum job_type: { push_message: 0 }, _prefix: :type
end
