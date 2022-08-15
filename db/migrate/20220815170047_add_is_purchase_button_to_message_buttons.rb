class AddIsPurchaseButtonToMessageButtons < ActiveRecord::Migration[7.0]
  def change
    add_column :message_buttons, :is_purchase_button, :boolean, default: false
  end
end
