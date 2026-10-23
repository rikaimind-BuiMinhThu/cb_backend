module ScenarioUserResponses
  class Statistic
    ANSWER_COUNT_KEYS = {
      'add' => :complete_count,
      'error' => :error_count,
      'upd' => :retry_count
    }.freeze
    USER_MESSAGE = 'user'.freeze

    def initialize(scenario_id:, start_date: nil, end_date: nil)
      @scenario_id = scenario_id
      @start_date = parse_date(start_date)&.beginning_of_day
      @end_date = parse_date(end_date)&.end_of_day
    end

    def stats
      event_stats = ScenarioUserResponseMessage.stats_for(
        scenario_id: @scenario_id,
        start_date: @start_date,
        end_date: @end_date
      )
      merge_answer_counts(event_stats, answer_counts_by_message_id)
    end

    def overall
      entry_count = ScenarioUserResponse.entry_count_for(
        scenario_id: @scenario_id,
        start_date: @start_date,
        end_date: @end_date
      )

      form_completed_count = ScenarioUserResponseStatus.completed_count(
        scenario_id: @scenario_id,
        start_date: @start_date,
        end_date: @end_date
      )

      pgs_cv_count = Order.pgs_cv_count(
        scenario_id: @scenario_id,
        start_date: @start_date,
        end_date: @end_date
      )

      impression_count = ScenarioUser.entry_count(
        scenario_id: @scenario_id,
        start_date: @start_date,
        end_date: @end_date
      )

      {
        entry_count: entry_count,
        form_completed_count: form_completed_count,
        form_completion_rate: entry_count > 0 ? ((form_completed_count.to_f / entry_count) * 100).round(2) : 0.0,
        pgs_cv_count: pgs_cv_count,
        pgs_cv_entry_rate: entry_count > 0 ? ((pgs_cv_count.to_f / entry_count) * 100).round(2) : 0.0,
        impression_count: impression_count
      }
    end

    private

    def parse_date(date_str)
      DateTime.parse(date_str.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def answer_counts_by_message_id
      totals = {}
      name_to_message_id = save_name_to_message_id

      response_counts.each do |(name, submit_type), count|
        message_id = name_to_message_id[name.to_s]
        count_key = ANSWER_COUNT_KEYS[submit_type.to_s]
        next if message_id.nil? || count_key.nil?

        totals[message_id] ||= empty_answer_counts
        totals[message_id][count_key] = [totals[message_id][count_key], count].max
      end

      totals
    end

    def response_counts
      ScenarioUserResponse
        .between(@start_date, @end_date)
        .where(scenario_id: @scenario_id)
        .where.not(data_input_name: [nil, ''])
        .group(:data_input_name, :submit_type)
        .count
    end

    def save_name_to_message_id
      scenario = Scenario.find_by(id: @scenario_id)
      return {} unless scenario

      messages = conversation_messages(scenario.conversation)
      messages.each_with_object({}) do |message, mapping|
        next unless message_belong_to(message) == USER_MESSAGE

        message_id = normalize_message_id(message_value(message, 'id'))
        next if message_id.nil?

        save_names_for(message).each do |name|
          mapping[name] ||= message_id
        end
      end
    end

    def conversation_messages(raw)
      parsed = raw.is_a?(Hash) ? raw : JSON.parse(raw.to_s)
      messages = parsed['messages'] || parsed[:messages]
      messages.is_a?(Array) ? messages : []
    rescue JSON::ParserError, TypeError
      []
    end

    def save_names_for(message)
      contents = message_value(message, 'message_content')
      return [] unless contents.is_a?(Array)

      contents.filter_map do |content|
        type = message_value(content, 'type').to_s
        next if type.empty?

        typed = message_value(content, type)
        next unless typed.is_a?(Hash)

        name = message_value(typed, 'save_input_content').to_s
        name.empty? ? nil : name
      end
    end

    def message_belong_to(message)
      message_value(message, 'belong_to').to_s
    end

    def message_value(record, key)
      return nil unless record.is_a?(Hash)

      record[key] || record[key.to_sym]
    end

    def normalize_message_id(value)
      return nil if value.nil? || value == ''
      return value if value.is_a?(Integer)

      string = value.to_s
      return string.to_i if string.match?(/\A\d+\z/)

      string
    end

    def empty_answer_counts
      { complete_count: 0, error_count: 0, retry_count: 0 }
    end

    def merge_answer_counts(event_stats, answer_counts)
      by_id = {}

      event_stats.each do |row|
        msg_id = normalize_message_id(row[:msg_id] || row['msg_id'])
        next if msg_id.nil?

        by_id[msg_id] = {
          msg_id: msg_id,
          appear_count: row[:appear_count] || row['appear_count'] || 0,
          error_count: row[:error_count] || row['error_count'] || 0,
          complete_count: row[:complete_count] || row['complete_count'] || 0,
          retry_count: row[:retry_count] || row['retry_count'] || 0
        }
      end

      answer_counts.each do |message_id, counts|
        row = by_id[message_id] ||= {
          msg_id: message_id,
          appear_count: 0,
          error_count: 0,
          complete_count: 0,
          retry_count: 0
        }
        row[:complete_count] = [row[:complete_count], counts[:complete_count]].max
        row[:error_count] = [row[:error_count], counts[:error_count]].max
        row[:retry_count] = [row[:retry_count], counts[:retry_count]].max
      end

      by_id.values.map do |row|
        appear_count = row[:appear_count]
        complete_count = row[:complete_count]
        rate = appear_count.positive? ? ((complete_count.to_f / appear_count) * 100).round(2) : 0.0
        row.merge(completion_rate: rate)
      end
    end
  end
end
