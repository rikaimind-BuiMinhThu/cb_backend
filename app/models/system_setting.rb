class SystemSetting < ApplicationRecord
  LEXICA_MAX_CHROME_KEY = "lexica_max_chrome"
  DEFAULT_LEXICA_MAX_CHROME = 10
  ABSOLUTE_MAX_CHROME = 20

  validates :key, presence: true, uniqueness: true

  def self.lexica_max_chrome
    raw = find_by(key: LEXICA_MAX_CHROME_KEY)&.value
    clamp_chrome(raw)
  end

  def self.lexica_max_chrome=(value)
    record = find_or_initialize_by(key: LEXICA_MAX_CHROME_KEY)
    record.value = clamp_chrome(value).to_s
    record.save!
    clamp_chrome(value)
  end

  def self.clamp_chrome(value)
    number = Integer(value)
    [[number, 1].max, ABSOLUTE_MAX_CHROME].min
  rescue ArgumentError, TypeError
    DEFAULT_LEXICA_MAX_CHROME
  end
end
