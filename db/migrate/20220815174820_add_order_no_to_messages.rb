class AddOrderNoToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :order_no, :integer
  end
end
