class Chatbot < ApplicationRecord
  belongs_to :user

  enum design_type: {pop: 0, flat: 1, material: 2}
  enum main_color: {red: 0, yellow: 1, orange: 2, blue: 3, green: 4, purple: 5, black: 6, white: 7}
  enum status: {off: 0, on: 1}, _prefix: true

  mount_base64_uploader :icon, ChatbotIconUploader

  validates :title, presence: true
  validates :subtitle, presence: true
  validates :design_type, presence: true
  validates :main_color, presence: true
  validates :status, presence: true
  validates :bot_name, presence: true
end
