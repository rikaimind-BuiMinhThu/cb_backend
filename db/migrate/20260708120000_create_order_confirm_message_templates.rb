class CreateOrderConfirmMessageTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :order_confirm_message_templates do |t|
      t.string :name, null: false
      t.text :config
      t.bigint :created_by_id

      t.timestamps
    end

    add_index :order_confirm_message_templates, :name, unique: true
    add_index :order_confirm_message_templates, :created_by_id
  end
end
