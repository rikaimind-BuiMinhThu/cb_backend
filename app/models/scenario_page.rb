class ScenarioPage < ApplicationRecord
  belongs_to :scenario

  enum num_type: {num_of_cv: 0, num_of_start: 1}

  validates :url, presence: true
end
