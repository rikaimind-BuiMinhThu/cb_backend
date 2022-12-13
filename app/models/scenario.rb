class Scenario < ApplicationRecord
  belongs_to :chatbot
  has_many :analytic_scenarios

  validates :name, presence: true, uniqueness: { scope: :chatbot }
end
