class AddClearLandingPageSessionToScenarios < ActiveRecord::Migration[6.0]
  def change
    add_column :scenarios, :is_clear_landing_page_session, :boolean, default: false, null: false
  end
end
