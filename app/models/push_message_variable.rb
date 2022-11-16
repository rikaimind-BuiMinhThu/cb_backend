class PushMessageVariable < ApplicationRecord
  belongs_to :push_message
  belongs_to :variable

  enum operator: {of: 0, is: 1, is_not: 2, contains: 3}, _prefix: :operator

  validates :value, presence: true
end
