module Lexica
  class BotOrders
    EMAIL_INPUT_NAMES = %w[user_email email].freeze
    EXISTING_ANSWER_NAMES = %w[user_email email].freeze
    NEW_MEMBER_ANSWER_NAMES = %w[
      user_email email user_name user_name_kana zip_code_address phone_number phone birth_date
    ].freeze

    def self.list(chatbot_id:, client_id:, result: nil, path: nil, start_date: nil, end_date: nil, page: nil)
      start_on = parse_date(start_date)
      return invalid_date if start_on == :invalid

      end_on = parse_date(end_date)
      return invalid_date if end_on == :invalid

      scope = filtered_scope(
        chatbot_id: chatbot_id,
        client_id: client_id,
        result: result,
        path: path,
        start_on: start_on,
        end_on: end_on
      )
      total = scope.count
      rows = scope.includes(:scenario).order(created_at: :desc).page(page)
      emails = emails_by_pair(rows)
      {
        data: rows.map { |row| list_json(row, emails: emails) },
        total: total
      }
    end

    def self.find_row(chatbot_id:, client_id:, id:)
      listing_scope(chatbot_id: chatbot_id, client_id: client_id).includes(:scenario).find_by(id: id)
    end

    def self.screenshot_available?(row)
      return false if row.blank?

      AmazonWebServices::RpaScreenshotS3.s3_key?(row.screenshot_path)
    end

    def self.step_screenshot_key(row, requested)
      return nil if row.blank?

      key = requested.to_s
      return nil unless AmazonWebServices::RpaScreenshotS3.s3_key?(key)
      return nil unless row.rpa_steps_array.any? { |step|
        step.is_a?(Hash) && step["screenshot_path"].to_s == key
      }

      key
    end

    def self.list_json(row, emails: nil)
      {
        id: row.id,
        created_at: row.created_at,
        start_time: row.start_time,
        end_time: row.end_time,
        result: row.result,
        path: row.path,
        path_label: row.path_label,
        payment: row.payment,
        payment_label: row.payment_label,
        email: emails ? emails[[row.scenario_id, row.user_input_id]] : email_for(row),
        sku: row.sku,
        lexica_order_id: row.lexica_order_id,
        last_step_description: row.last_step_description,
        scenario_id: row.scenario_id,
        user_input_id: row.user_input_id,
        chrome_slot_defer_count: row.chrome_slot_defer_count,
        chrome_slot_retry_count: row.chrome_slot_retry_count
      }
    end

    def self.detail_json(row)
      answers = ScenarioUserResponse.where(scenario_id: row.scenario_id, user_input_id: row.user_input_id)
      list_json(row).merge(
        product_url: row.product_url,
        cart_url: row.cart_url,
        start_time: row.start_time,
        end_time: row.end_time,
        error_kind: row.error_kind,
        error_message: row.error_message,
        screenshot_path: row.screenshot_path,
        has_screenshot: screenshot_available?(row),
        masked_pan: row.masked_pan,
        card_expiry: row.card_expiry,
        card_holder: row.card_holder,
        rpa_steps: row.rpa_steps_array,
        answers: answers_json(row, answers)
      )
    end

    def self.answers_json(row, answers)
      names = row.path.to_s == "existing" ? EXISTING_ANSWER_NAMES : NEW_MEMBER_ANSWER_NAMES
      answers.select { |answer| names.include?(answer.data_input_name.to_s) }.map do |answer|
        { data_input_name: answer.data_input_name, value: redact_answer(answer) }
      end
    end

    def self.email_for(row)
      ScenarioUserResponse.where(
        scenario_id: row.scenario_id,
        user_input_id: row.user_input_id,
        data_input_name: EMAIL_INPUT_NAMES
      ).last&.value
    end

    def self.filtered_scope(chatbot_id:, client_id:, result:, path:, start_on:, end_on:)
      scope = listing_scope(chatbot_id: chatbot_id, client_id: client_id)
      scope = scope.with_result(result) if result.present?
      scope = scope.with_path(path) if path.present?
      scope = scope.created_on_or_after(start_on) if start_on
      scope = scope.created_on_or_before(end_on) if end_on
      scope
    end
    private_class_method :filtered_scope

    def self.listing_scope(chatbot_id:, client_id:)
      ScenarioUserResponseSeleniumResult.for_listing(chatbot_id: chatbot_id, client_id: client_id)
    end
    private_class_method :listing_scope

    def self.emails_by_pair(rows)
      pairs = rows.map { |row| [row.scenario_id, row.user_input_id] }.uniq
      return {} if pairs.empty?

      table = ScenarioUserResponse.arel_table
      pair_match = pairs.map { |scenario_id, user_input_id|
        table[:scenario_id].eq(scenario_id).and(table[:user_input_id].eq(user_input_id))
      }.reduce(:or)

      ScenarioUserResponse
        .where(data_input_name: EMAIL_INPUT_NAMES)
        .where(pair_match)
        .order(:id)
        .each_with_object({}) do |answer, emails|
          emails[[answer.scenario_id, answer.user_input_id]] = answer.value
        end
    end
    private_class_method :emails_by_pair

    def self.parse_date(raw)
      return nil if raw.blank?
      return :invalid unless raw.is_a?(String) || raw.is_a?(Date) || raw.is_a?(Time)

      raw.to_date
    rescue ArgumentError, TypeError, Date::Error => error
      Rails.logger.warn("Lexica::BotOrders.parse_date: #{error.message}")
      :invalid
    end
    private_class_method :parse_date

    def self.invalid_date
      { error: { code: 2, message: "invalid date" } }
    end
    private_class_method :invalid_date

    def self.redact_answer(answer)
      return "********" if answer.data_input_name.to_s == "password"

      answer.value
    end
    private_class_method :redact_answer
  end
end
