class AddHtmlUgcConfigToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :is_used_html_ugc, :boolean, default: false, null: false
    add_column :scenarios, :is_ugc_instagram, :boolean, default: false, null: false
    add_column :scenarios, :is_ugc_tiktok, :boolean, default: false, null: false
    add_column :scenarios, :is_ugc_review, :boolean, default: false, null: false
    add_column :scenarios, :html_ugc_config_content, :text
  end
end
