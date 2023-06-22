class AddLandingPageProductUrlToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :landing_page_product_url, :string
  end
end
