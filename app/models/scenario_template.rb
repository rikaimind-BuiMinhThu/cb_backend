class ScenarioTemplate < ApplicationRecord
  include ScenarioContentCopyable

  belongs_to :created_by, class_name: "User", optional: true

  validates :name, presence: true, uniqueness: true
  validates :scenario_type, inclusion: { in: %w[payment faq] }, allow_nil: false

  def apply_to!(scenario)
    preserved_name = scenario.name
    self.class.copy_content_attributes(from: self, to: scenario)
    scenario.name = preserved_name
    merge_extra_config_into_conversation!(scenario)
    scenario
  end

  def merge_extra_config_into_conversation!(scenario)
    extra = extra_config_hash
    return if extra.blank?

    conversation_data =
      if scenario.conversation.present?
        JSON.parse(scenario.conversation)
      else
        {}
      end

    extra.each do |key, value|
      conversation_data[key.to_s] = value unless value.nil?
    end

    scenario.conversation = JSON.generate(conversation_data)
  rescue JSON::ParserError
    nil
  end

  def extra_config_hash
    return {} if extra_config.blank?

    JSON.parse(extra_config)
  rescue JSON::ParserError
    {}
  end

  def extra_config_hash=(value)
    self.extra_config = value.present? ? JSON.generate(value.as_json) : nil
  end
end
