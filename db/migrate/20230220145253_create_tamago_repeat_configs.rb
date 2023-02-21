class CreateTamagoRepeatConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :tamago_repeat_configs do |t|
      t.integer :scenario_id
      t.text :tamago_landing_page_url
      t.text :add_to_cart_button_selector
      t.boolean :is_regular_product
      t.integer :email_confirm_field
      t.integer :name_kana_field

      t.timestamps
    end
  end
end
