class PushMessage < ApplicationRecord
  belongs_to :email, optional: true
  belongs_to :chatbot

  has_many :push_message_variables

  enum sending_method: {email: 0, sms: 1}, _prefix: :sending_method
  enum has_timezone_exclusion: {no: false, yes: true}, _prefix: :has_timezone_exclusion
  enum subscribe_status: {unsubscribe: false, subscribe: true}, _prefix: :has_timezone_exclusion

  validates :title, presence: true
  validates :started_at, presence: true
  validates :email, presence: true, if: -> { sending_method_email? }
  validates :last_message_datetime_since, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 36 }
end
