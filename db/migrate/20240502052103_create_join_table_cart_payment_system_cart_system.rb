class CreateJoinTableCartPaymentSystemCartSystem < ActiveRecord::Migration[7.0]
  def change
    create_join_table :cart_payment_systems, :cart_systems do |t|
      # t.index [:cart_payment_system_id, :cart_system_id]
      # t.index [:cart_system_id, :cart_payment_system_id]
    end
  end
end
