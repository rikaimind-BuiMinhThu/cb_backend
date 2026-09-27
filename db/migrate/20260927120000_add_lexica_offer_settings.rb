class AddLexicaOfferSettings < ActiveRecord::Migration[7.0]
  def up
    add_column :scenarios, :lexica_upsell_product_url, :string unless column_exists?(:scenarios, :lexica_upsell_product_url)
    add_column :scenarios, :lexica_upsell_sku, :string unless column_exists?(:scenarios, :lexica_upsell_sku)
    add_column :scenarios, :lexica_cross_sell_product_url, :string unless column_exists?(:scenarios, :lexica_cross_sell_product_url)
    add_column :scenarios, :lexica_cross_sell_sku, :string unless column_exists?(:scenarios, :lexica_cross_sell_sku)
    add_column :scenarios, :lexica_offer_chat, :boolean, default: true, null: false unless column_exists?(:scenarios, :lexica_offer_chat)
    add_column :scenarios, :lexica_offer_confirm_upsell, :boolean, default: true, null: false unless column_exists?(:scenarios, :lexica_offer_confirm_upsell)
    add_column :scenarios, :lexica_offer_confirm_cross_sell, :boolean, default: false, null: false unless column_exists?(:scenarios, :lexica_offer_confirm_cross_sell)
    add_column :scenarios, :lexica_offer_thanks_upsell, :boolean, default: true, null: false unless column_exists?(:scenarios, :lexica_offer_thanks_upsell)
    add_column :scenarios, :lexica_offer_thanks_cross_sell, :boolean, default: true, null: false unless column_exists?(:scenarios, :lexica_offer_thanks_cross_sell)

    unless column_exists?(:scenario_user_response_selenium_results, :resolved_sku)
      add_column :scenario_user_response_selenium_results, :resolved_sku, :string
    end
    unless column_exists?(:scenario_user_response_selenium_results, :resolved_product_url)
      add_column :scenario_user_response_selenium_results, :resolved_product_url, :string
    end
    unless column_exists?(:scenario_user_response_selenium_results, :offer_surfaces)
      add_column :scenario_user_response_selenium_results, :offer_surfaces, :text
    end
  end

  def down
    remove_column :scenarios, :lexica_upsell_product_url if column_exists?(:scenarios, :lexica_upsell_product_url)
    remove_column :scenarios, :lexica_upsell_sku if column_exists?(:scenarios, :lexica_upsell_sku)
    remove_column :scenarios, :lexica_cross_sell_product_url if column_exists?(:scenarios, :lexica_cross_sell_product_url)
    remove_column :scenarios, :lexica_cross_sell_sku if column_exists?(:scenarios, :lexica_cross_sell_sku)
    remove_column :scenarios, :lexica_offer_chat if column_exists?(:scenarios, :lexica_offer_chat)
    remove_column :scenarios, :lexica_offer_confirm_upsell if column_exists?(:scenarios, :lexica_offer_confirm_upsell)
    remove_column :scenarios, :lexica_offer_confirm_cross_sell if column_exists?(:scenarios, :lexica_offer_confirm_cross_sell)
    remove_column :scenarios, :lexica_offer_thanks_upsell if column_exists?(:scenarios, :lexica_offer_thanks_upsell)
    remove_column :scenarios, :lexica_offer_thanks_cross_sell if column_exists?(:scenarios, :lexica_offer_thanks_cross_sell)
    remove_column :scenario_user_response_selenium_results, :resolved_sku if column_exists?(:scenario_user_response_selenium_results, :resolved_sku)
    remove_column :scenario_user_response_selenium_results, :resolved_product_url if column_exists?(:scenario_user_response_selenium_results, :resolved_product_url)
    remove_column :scenario_user_response_selenium_results, :offer_surfaces if column_exists?(:scenario_user_response_selenium_results, :offer_surfaces)
  end
end
