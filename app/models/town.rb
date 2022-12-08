class Town < ApplicationRecord
  validates :town_name, presence: true, uniqueness: true
end
