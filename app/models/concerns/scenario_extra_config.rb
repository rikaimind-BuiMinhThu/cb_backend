module ScenarioExtraConfig
  extend ActiveSupport::Concern

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
