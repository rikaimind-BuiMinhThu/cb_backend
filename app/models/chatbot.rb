class Chatbot < ApplicationRecord
  has_many :user_chatbots, dependent: :destroy
  has_many :users, through: :user_chatbots
  has_many :emails, through: :user_chatbots
  belongs_to :user
  has_many :variables, dependent: :destroy
  has_many :scenarios, dependent: :destroy
  has_many :push_messages, dependent: :destroy
  # has_many :history_click_urls, dependent: :destroy

  enum design_type: {pop: 0, flat: 1, material: 2}
  enum main_color: {pink: 0, yellow: 1, orange: 2, blue: 3, green: 4, purple: 5, black: 6, white: 7}
  enum status: {off: 0, on: 1}, _prefix: true

  mount_base64_uploader :icon, ChatbotIconUploader

  validates :title, presence: true
  validates :subtitle, presence: true
  validates :design_type, presence: true
  validates :main_color, presence: true
  validates :status, presence: true
  validates :bot_name, presence: true
end
