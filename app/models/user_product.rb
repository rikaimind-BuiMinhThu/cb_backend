class UserProduct < ApplicationRecord
  belongs_to :user
  belongs_to :product

  after_destroy :delete_orphaned_product

  private

  def delete_orphaned_product
    product.destroy if product.users.empty?
  end
end
