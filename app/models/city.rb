class City < ApplicationRecord
  validates :city_name, presence: true, uniqueness: true
end
