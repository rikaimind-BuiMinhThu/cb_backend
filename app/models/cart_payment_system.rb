class CartPaymentSystem < ApplicationRecord
  has_and_belongs_to_many :cart_systems, join_table: 'cart_payment_systems_systems'
  belongs_to :user
  belongs_to :payment_system
end
