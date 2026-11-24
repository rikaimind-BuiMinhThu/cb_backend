class AddUniqueIndexOrdersOnClientScenarioUser < ActiveRecord::Migration[6.1]
  def up
    rows = ActiveRecord::Base.connection.select_all(<<~SQL.squish)
      SELECT client_id, scenario_id, user_input_id, MIN(id) AS keep_id, COUNT(*) AS dup_count
      FROM orders
      GROUP BY client_id, scenario_id, user_input_id
      HAVING COUNT(*) > 1
    SQL

    if rows.any?
      total = rows.sum { |row| row["dup_count"].to_i - 1 }
      say "orders unique index: #{rows.length} duplicate groups (#{total} extra rows)"

      # Destructive delete is opt-in. Default: archive extras by nulling user_input_id
      # so billing history stays, then add the unique index on remaining rows.
      if ENV["ORDERS_DEDUP_DELETE"] == "1"
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
      else
        rows.each do |row|
          execute(
            ActiveRecord::Base.sanitize_sql_array([
              "UPDATE orders SET user_input_id = CONCAT(user_input_id, '__dup_', id) " \
              "WHERE client_id = ? AND scenario_id = ? AND user_input_id = ? AND id <> ?",
              row["client_id"],
              row["scenario_id"],
              row["user_input_id"],
              row["keep_id"]
            ])
          )
        end
      end
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
