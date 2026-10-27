module Lexica
  class CardPayload
    PAN_REGEX = /\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d+/

    def self.contains_pan?(raw)
      text = decoded_text(raw)
      return false if text.blank?
      return false if parsed_token?(text)

      digits = text.gsub(/[^\d]/, "")
      return true if digits.length.between?(13, 19)
      return true if text.match?(PAN_REGEX)

      false
    end

    # The stored credit_card_payment is a JWT (see ScenarioUserResponse#value=). Counting
    # digits on the encoded JWT is random: the same token payload can pass or be rejected
    # depending on how many digits the base64 happens to contain. Decode it first.
    def self.decoded_text(raw)
      text = raw.to_s
      return text unless text.start_with?("eyJ")

      data = JWT.decode(text, ScenarioUserResponse::SECRET_KEY)[0]["data"]
      data.is_a?(String) ? data : data.to_json
    rescue JWT::DecodeError
      text
    end

    def self.parsed_token?(raw)
      data = JSON.parse(raw)
      data["token_key"].present? || data[:token_key].present?
    rescue JSON::ParserError
      false
    end
  end
end
