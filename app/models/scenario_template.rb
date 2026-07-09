class ScenarioTemplate < ApplicationRecord
  include ScenarioContentCopyable
  include ScenarioExtraConfig

  belongs_to :created_by, class_name: "User", optional: true

  validates :name, presence: true, uniqueness: true
  validates :scenario_type, inclusion: { in: %w[payment faq] }, allow_nil: false

  def apply_to!(scenario)
    preserved_name = scenario.name
    self.class.copy_content_attributes(from: self, to: scenario)
    scenario.name = preserved_name
    scenario
  end
end
