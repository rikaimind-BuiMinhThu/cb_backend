class ShopifyOrder < ApplicationRecord
  belongs_to :cart_payment_system
end
