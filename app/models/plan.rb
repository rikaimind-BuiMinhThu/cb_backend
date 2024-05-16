class Plan < ApplicationRecord
  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :price, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "id", "name", "price", "updated_at", "code"]
  end
end
