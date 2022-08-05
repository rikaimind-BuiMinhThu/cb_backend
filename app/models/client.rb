class Client < ApplicationRecord
  acts_as_paranoid
  has_many :users, dependent: :destroy

  enum status: {active: 0, pause: 1, ended: 2, trial: 3}
  enum plan: {startup: 0, premium: 1, expert: 2, complete: 4}

  mount_base64_uploader :logo_url, PictureUploader

  validates :subscription_end_at, comparison: { greater_than: :subscription_start_at }

end
