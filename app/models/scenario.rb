class Scenario < ApplicationRecord
  belongs_to :chatbot
  has_many :analytic_scenarios, dependent: :destroy
  has_many :scenario_pages, dependent: :destroy
  has_many :scenario_user_responses
  has_one :tamago_repeat_config

  validates :name, presence: true, uniqueness: { scope: :chatbot }
end
