class ChatLog
  def initialize(scenario_user_responses)
    @scenario_user_responses = scenario_user_responses
  end

  def get_grouped_response
    @scenario_user_responses
      .group_by { |r| [r.scenario_id, r.user_input_id] }
      .map do |(scenario_id, user_input_id), group|
        status_record = ScenarioUserResponseStatus.find_by(
          scenario_id: scenario_id,
          user_input_id: user_input_id
        )

        is_done = status_record&.status&.to_sym == :finished

        {
          scenario_id: scenario_id,
          user_input_id: user_input_id,
          newest: group.first.newest,
          is_done: is_done
        }
      end
  end
end
