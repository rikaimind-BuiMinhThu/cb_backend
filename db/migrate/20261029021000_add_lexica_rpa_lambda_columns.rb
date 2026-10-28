class AddLexicaRpaLambdaColumns < ActiveRecord::Migration[7.0]
  def change
    add_column :scenario_user_response_selenium_results, :order_submitted_at, :datetime
    add_column :scenario_user_response_selenium_results, :rpa_attempt, :integer, default: 0, null: false
    add_column :scenario_user_response_selenium_results, :claimed_at, :datetime
    add_column :scenario_user_response_selenium_results, :defer_started_at, :datetime
  end
end
