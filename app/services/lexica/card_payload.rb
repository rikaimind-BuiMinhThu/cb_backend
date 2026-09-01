module Lexica
  class CardPayload
    PAN_REGEX = /\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d[ \-]*\d+/

    def self.contains_pan?(raw)
      text = raw.to_s
      return false if text.blank?
      return false if parsed_token?(text)

      digits = text.gsub(/[^\d]/, "")
      return true if digits.length.between?(13, 19)
      return true if text.match?(PAN_REGEX)

      false
    end

    def self.parsed_token?(raw)
      data = JSON.parse(raw)
      data["token_key"].present? || data[:token_key].present?
    rescue JSON::ParserError
      false
    end
  end
end
