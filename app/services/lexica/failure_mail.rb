module Lexica
  class FailureMail
    def self.deliver(result, kind, message)
      scenario = result.scenario
      client = scenario.chatbot&.user&.client
      email = client&.email.presence || scenario.chatbot&.user&.email
      return if email.blank?

      user_email = scenario.scenario_user_responses
        .where(user_input_id: result.user_input_id, data_input_name: %w[user_email email])
        .last&.value
      OrderFailedMailer.send_email(
        email,
        email,
        {
          shop_name: client&.name,
          user_email: user_email,
          path: result.path,
          error_kind: kind,
          error_message: message.to_s.slice(0, 2000),
          user_input_id: result.user_input_id
        }
      ).deliver_later
    rescue StandardError => error
      Rails.logger.error("OrderFailedMailer failed: #{error.message}")
    end
  end
end
