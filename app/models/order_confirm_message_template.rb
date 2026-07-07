class OrderConfirmMessageTemplate < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }

  def config_hash
    return {} if config.blank?

    JSON.parse(config)
  rescue JSON::ParserError
    {}
  end

  def config_hash=(value)
    self.config = value.present? ? JSON.generate(value.as_json) : nil
  end
end
