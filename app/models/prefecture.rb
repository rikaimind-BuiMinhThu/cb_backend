class Prefecture < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
