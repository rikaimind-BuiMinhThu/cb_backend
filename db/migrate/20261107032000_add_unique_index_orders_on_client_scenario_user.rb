class AddUniqueIndexOrdersOnClientScenarioUser < ActiveRecord::Migration[6.1]
  def up
    rows = ActiveRecord::Base.connection.select_all(<<~SQL.squish)
      SELECT client_id, scenario_id, user_input_id, MIN(id) AS keep_id
      FROM orders
      GROUP BY client_id, scenario_id, user_input_id
      HAVING COUNT(*) > 1
    SQL

    rows.each do |row|
      execute(
        ActiveRecord::Base.sanitize_sql_array([
          "DELETE FROM orders WHERE client_id = ? AND scenario_id = ? AND user_input_id = ? AND id <> ?",
          row["client_id"],
          row["scenario_id"],
          row["user_input_id"],
          row["keep_id"]
        ])
      )
    end

    add_index :orders,
              %i[client_id scenario_id user_input_id],
              unique: true,
              name: "index_orders_on_client_scenario_user_unique"
  end

  def down
    remove_index :orders, name: "index_orders_on_client_scenario_user_unique"
  end
end
