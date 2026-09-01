class AddLexicaRpaSchema < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :lexica_max_chrome, :integer

    add_column :payment_gateways, :token_js_url, :string
    add_column :payment_gateways, :ipcode, :string

    add_column :scenarios, :order_result_mode, :string, default: "wait"
    add_column :scenarios, :lexica_cart_url, :string

    add_column :scenario_user_response_selenium_results, :path, :string
    add_column :scenario_user_response_selenium_results, :payment, :string
    add_column :scenario_user_response_selenium_results, :lexica_order_id, :string
    add_column :scenario_user_response_selenium_results, :sku, :string
    add_column :scenario_user_response_selenium_results, :product_url, :string
    add_column :scenario_user_response_selenium_results, :cart_url, :string
    add_column :scenario_user_response_selenium_results, :error_kind, :string
    add_column :scenario_user_response_selenium_results, :screenshot_path, :string
    add_column :scenario_user_response_selenium_results, :error_message, :text
    add_column :scenario_user_response_selenium_results, :rpa_steps, :text
    add_column :scenario_user_response_selenium_results, :masked_pan, :string
    add_column :scenario_user_response_selenium_results, :card_expiry, :string
    add_column :scenario_user_response_selenium_results, :card_holder, :string
    add_column :scenario_user_response_selenium_results, :token_key, :string
    add_index :scenario_user_response_selenium_results, :user_input_id, name: "index_selenium_results_on_user_input_id"

    create_table :system_settings do |t|
      t.string :key, null: false
      t.string :value
      t.timestamps
    end
    add_index :system_settings, :key, unique: true
  end
end
