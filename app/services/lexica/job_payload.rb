require "json"
require "jwt"

module Lexica
  class JobPayload
    SCENARIO_FIELDS = %w[
      id merchandise_id landing_page_product_url lexica_cart_url
      lexica_upsell_sku lexica_upsell_product_url
      lexica_cross_sell_sku lexica_cross_sell_product_url
      lexica_offer_chat lexica_offer_confirm_upsell lexica_offer_confirm_cross_sell
      lexica_offer_thanks_upsell lexica_offer_thanks_cross_sell
    ].freeze
    PAN_KEYS = %w[
      card_number number cvc security_code
      card_number1 card_number2 card_number3 card_number4
    ].freeze

    def self.build(result)
      new(result).build
    end

    def initialize(result)
      @result = result
    end

    def build
      scenario = @result.scenario
      conversations = scenario.scenario_user_responses.where(user_input_id: @result.user_input_id)
      {
        "result_id" => @result.id,
        "client_id" => @result.client_id,
        "user_input_id" => @result.user_input_id,
        "scenario" => scenario_hash(scenario),
        "conversations" => conversations.map { |row| conversation_hash(row) }
      }
    end

    def self.card_for_lambda(raw)
      new(nil).card_for_lambda(raw)
    end

    def card_for_lambda(raw)
      card = decode_card(raw)
      PAN_KEYS.each { |key| card.delete(key) }
      JSON.generate(card)
    end

    private

    def scenario_hash(scenario)
      SCENARIO_FIELDS.each_with_object({}) do |field, out|
        out[field] = scenario.public_send(field) if scenario.respond_to?(field)
      end
    end

    def conversation_hash(row)
      name = row.data_input_name.to_s
      value =
        case name
        when "password"
          decode_secret(row.value)
        when "credit_card_payment"
          card_for_lambda(row.value)
        else
          row.value
        end
      {
        "data_input_name" => name,
        "value" => value,
        "user_input_id" => row.user_input_id
      }
    end

    def decode_secret(raw)
      return nil if raw.blank?

      JWT.decode(raw, secret_key)[0]["data"]
    rescue StandardError
      raw
    end

    def decode_card(raw)
      return {} if raw.blank?

      parsed = parse_json(raw)
      return parsed if parsed["token_key"].present?

      decoded = JWT.decode(raw, secret_key)[0]["data"]
      decoded.is_a?(String) ? parse_json(decoded) : stringify_keys(decoded)
    rescue StandardError
      parse_json(raw)
    end

    def parse_json(raw)
      return {} if raw.blank?
      return stringify_keys(raw) if raw.is_a?(Hash)

      stringify_keys(JSON.parse(raw.to_s))
    rescue JSON::ParserError
      {}
    end

    def stringify_keys(hash)
      return {} unless hash.is_a?(Hash)

      hash.each_with_object({}) { |(key, value), out| out[key.to_s] = value }
    end

    def secret_key
      Rails.application.secrets.secret_refresh_token
    end
  end
end
