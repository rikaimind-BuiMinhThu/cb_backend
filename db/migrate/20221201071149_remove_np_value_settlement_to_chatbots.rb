class RemoveNpValueSettlementToChatbots < ActiveRecord::Migration[7.0]
  def up
    remove_column :chatbots, :np_settlement_min_value
    remove_column :chatbots, :np_settlement_max_value
    remove_column :chatbots, :np_settlement_fee_value
  end

  def down
    add_column :chatbots, :np_settlement_min_value, :integer
    add_column :chatbots, :np_settlement_max_value, :integer
    add_column :chatbots, :np_settlement_fee_value, :integer
  end
end
