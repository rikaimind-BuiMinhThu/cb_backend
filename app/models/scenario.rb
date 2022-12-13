class Scenario < ApplicationRecord
  belongs_to :chatbot
  has_many :analytic_scenarios
  has_many :scenario_pages

  validates :name, presence: true, uniqueness: { scope: :chatbot }
end
