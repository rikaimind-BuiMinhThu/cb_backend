class HotTemplate < ApplicationRecord

  # MAXIMUM_ENTRY = 3

  belongs_to :message_group

  # validate :validate_maximum_hot_templates, on: :create

  # def validate_maximum_hot_templates
  #   errors.add(:base, "exceed maximum entry") if HotTemplate.all.length >= MAXIMUM_ENTRY
  # end
end
