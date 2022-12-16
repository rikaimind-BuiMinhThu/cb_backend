class Scenario < ApplicationRecord
  belongs_to :chatbot
  has_many :analytic_scenarios, dependent: :destroy
  has_many :scenario_pages, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :chatbot }
end
