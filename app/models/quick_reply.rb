class QuickReply < ApplicationRecord
  belongs_to :message, dependent: :destroy

  validates :title, length: { maximum: 20 }, presence: true
  validates :message, presence: true
end
