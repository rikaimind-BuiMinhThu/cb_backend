class Variable < ApplicationRecord
  belongs_to :chatbot

  validates :variable_name, presence: true, uniqueness: { scope: :chatbot }
  validates :chatbot_id, presence: true
end
