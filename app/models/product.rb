class Product < ApplicationRecord
  has_many :variants, dependent: :destroy
  has_many :user_products, dependent: :destroy
  has_many :users, through: :user_products
end
