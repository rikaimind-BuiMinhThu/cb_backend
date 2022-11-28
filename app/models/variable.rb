class Variable < ApplicationRecord
  belongs_to :chatbot
  has_many :push_message_variables, dependent: :destroy

  DEFAULT_VARIABLES = ['current_url', 'current_url_param', 'current_url_title', 'user_id', 'bot_id', 'preview_flg', 'user_ip_address', 'user_country', 'user_city', 'user_device', 'user_browser', 'user_agent', 'cv_datetime', 'cv_flg', 'start_datetime', 'user_referer_firstopen', 'user_referer_current']

  validates :variable_name, presence: true, uniqueness: { scope: :chatbot }, exclusion: { in: DEFAULT_VARIABLES, message: "%{value} is reserved." }
  validates :chatbot_id, presence: true
end
