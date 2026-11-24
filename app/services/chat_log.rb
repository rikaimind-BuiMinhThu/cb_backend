class ChatLog
  def initialize(scenario_user_responses)
    @scenario_user_responses = scenario_user_responses
  end

  def get_grouped_response
    groups = @scenario_user_responses.group_by { |r| [r.scenario_id, r.user_input_id] }
    keys = groups.keys
    order_rows = preload_latest_by_visitor(ScenarioUserResponseSeleniumResult, keys)
    status_rows = preload_latest_by_visitor(ScenarioUserResponseStatus, keys)

    groups.map do |(scenario_id, user_input_id), group|
      key = [scenario_id, user_input_id]
      status_record = status_rows[key]
      order_row = order_rows[key]

      {
        scenario_id: scenario_id,
        user_input_id: user_input_id,
        newest: group.first.newest,
        is_done: status_record&.status&.to_sym == :finished,
        order_status: order_row&.result,
        order_id: order_row&.id
      }
    end
  end

  private

  def preload_latest_by_visitor(model, keys)
    return {} if keys.empty?

    scenario_ids = keys.map(&:first).uniq
    user_input_ids = keys.map(&:last).uniq
    rows = model.where(scenario_id: scenario_ids, user_input_id: user_input_ids).order(id: :desc)

    selected = {}
    rows.each do |row|
      key = [row.scenario_id, row.user_input_id]
      next if selected.key?(key)

      selected[key] = row
    end
    selected
  end
end
