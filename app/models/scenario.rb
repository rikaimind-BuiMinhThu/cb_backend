class Scenario < ApplicationRecord
  belongs_to :chatbot

  validates :name, presence: true, uniqueness: { scope: :chatbot }
end
