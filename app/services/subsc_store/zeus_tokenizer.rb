require "faraday"
require "json"
require "uri"

module SubscStore
  class ZeusTokenizer
    TOKEN_URL = "https://linkpt.cardservice.co.jp/cgi-bin/token/token.cgi".freeze

    def initialize(ip_code)
      @ip_code = ip_code
    end

    def tokenize(card)
      raise Error, "zeus_ip_code is blank" if @ip_code.blank?
      raise Error, "card number is blank" if card[:card_number].blank?

      response = Faraday.post(TOKEN_URL) do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.options.timeout = 20
        req.body = URI.encode_www_form(
          clientip: @ip_code,
          cardnumber: digits(card[:card_number]),
          expyy: expire_year(card[:year] || card[:expire_year]),
          expmm: expire_month(card[:month] || card[:expire_month]),
          securitycode: card[:cvc].to_s
        )
      end

      parsed = parse_body(response.body)
      token_key = parsed["token_key"] || parsed["token"] || parsed.dig("result", "token_key")
      raise Error.new("ZEUS tokenize failed", status: response.status, body: parsed) if token_key.blank?

      {
        token_key: token_key,
        masked_card_number: mask_card(card[:card_number]),
        brand: brand_from_pan(card[:card_number]),
        expire_month: expire_month(card[:month] || card[:expire_month]),
        expire_year: expire_year(card[:year] || card[:expire_year]),
        holder_name: card[:card_holder] || card[:holder_name]
      }
    end

    def self.mask_card(number)
      digits = number.to_s.gsub(/\D/, "")
      return "" if digits.blank?

      prefix = digits[0, 6]
      suffix = digits[-3, 3]
      "#{prefix}*******#{suffix}"
    end

    def self.brand_from_pan(number)
      digits = number.to_s.gsub(/\D/, "")
      return "visa" if digits.start_with?("4")
      return "mastercard" if digits.match?(/\A5[1-5]/) || digits.match?(/\A2[2-7]/)
      return "amex" if digits.match?(/\A3[47]/)
      return "jcb" if digits.start_with?("35")
      return "diners" if digits.match?(/\A3[068]/)

      "visa"
    end

    private

    def parse_body(body)
      return {} if body.blank?

      JSON.parse(body)
    rescue JSON::ParserError
      token = body.to_s[/token_key["']?\s*[:=]\s*["']?([0-9a-zA-Z]+)/, 1]
      token.present? ? { "token_key" => token } : { "raw" => body }
    end

    def digits(value)
      value.to_s.gsub(/\D/, "")
    end

    def expire_month(value)
      value.to_i.to_s.rjust(2, "0")
    end

    def expire_year(value)
      year = value.to_s.gsub(/\D/, "")
      year.length >= 4 ? year[-2, 2] : year.rjust(2, "0")
    end

    def mask_card(number)
      self.class.mask_card(number)
    end

    def brand_from_pan(number)
      self.class.brand_from_pan(number)
    end
  end
end
