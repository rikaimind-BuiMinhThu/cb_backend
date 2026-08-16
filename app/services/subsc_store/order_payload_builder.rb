require "json"

module SubscStore
  class OrderPayloadBuilder
    SECRET_KEY = Rails.application.secrets.secret_refresh_token

    def initialize(scenario, conversations, credit_card: {}, payment_config: nil)
      @scenario = scenario
      @conversations = conversations
      @credit_card = (credit_card || {}).with_indifferent_access
      @payment_config = payment_config
      @client = scenario.owning_client
      @config = scenario.subsc_store_config.with_indifferent_access
    end

    def build
      address = client_address
      {
        client_address: address,
        settlement: settlement,
        additional_customer_form_answers: [],
        frequency_id: int_or_nil(@config[:frequency_id]),
        shipments: [shipment(address)],
        user: user_payload,
        is_chatbot: true,
        is_skip_tds: false,
        order_items: order_items
      }.compact
    end

    private

    def client_address
      name = parse_json(find_response("user_name")) || {}
      kana = parse_json(find_response("user_name_kana")) || {}
      data_address = parse_json(find_response("zip_code_address")) || {}

      {
        family_name: name["valueLeft"] || name["family_name"],
        first_name: name["valueRight"] || name["first_name"],
        family_name_kana: kana["valueLeft"] || kana["family_name_kana"],
        first_name_kana: kana["valueRight"] || kana["first_name_kana"],
        zip_code: zip_code(data_address),
        state_id: state_id(data_address),
        city: data_address["value_city"] || data_address["city"],
        address: data_address["value_address"] || data_address["address"],
        building_name: data_address["value_building_name"] || data_address["building_name"],
        tel: find_response("phone_number").to_s.gsub("-", ""),
        email: find_response("user_email")
      }.compact
    end

    def user_payload
      password = decode_jwt(find_response("password"))
      birthday = parse_json(find_response("birth_date")) || {}
      payload = {
        account_kind: password.present? ? 1 : 2,
        birthday: birthday_value(birthday),
        gender_shop_id: gender_shop_id(find_response("sex"))
      }
      if password.present?
        payload[:password] = password
        payload[:password_confirmation] = password
      end
      payload.compact
    end

    def settlement
      if find_response("credit_card_payment").present?
        {
          payment_method_shop_id: credit_method_id,
          is_skip_tds: false,
          credit_card: credit_card_payload
        }.compact
      elsif find_response("np_delivery_payment").present?
        { payment_method_shop_id: np_method_id }
      else
        raise Error, "Unsupported payment method (v1 supports ZEUS credit or NP only)"
      end
    end

    def credit_card_payload
      card = decoded_card_data
      token_key = @credit_card[:token_key].presence || card[:token_key]
      if token_key.blank? && @client&.use_subsc_store_mock?
        token_key = "mock_token_key"
      elsif token_key.blank? && card[:card_number].present? && @payment_config
        tokenized = ZeusTokenizer.new(@payment_config.public_tokenize_config[:zeus_ip_code]).tokenize(card)
        token_key = tokenized[:token_key]
        card = card.merge(tokenized)
      end
      raise Error, "ZEUS token_key is missing" if token_key.blank?

      {
        token_key: token_key,
        masked_card_number: @credit_card[:masked_card_number].presence || card[:masked_card_number] || ZeusTokenizer.mask_card(card[:card_number]),
        brand: @credit_card[:brand].presence || card[:brand] || ZeusTokenizer.brand_from_pan(card[:card_number]),
        expire_month: expire_month(@credit_card[:expire_month].presence || card[:month] || card[:expire_month]),
        expire_year: expire_year(@credit_card[:expire_year].presence || card[:year] || card[:expire_year]),
        holder_name: @credit_card[:holder_name].presence || card[:card_holder] || card[:holder_name],
        is_default: false
      }.compact
    end

    def decoded_card_data
      encrypted = find_response("credit_card_payment")
      return @credit_card if encrypted.blank?

      parsed = parse_json(decode_jwt(encrypted)) || {}
      parsed.with_indifferent_access.merge(@credit_card)
    rescue StandardError
      @credit_card
    end

    def order_items
      quantity = (find_response("quantity").presence || 1).to_i
      item_kind = (@config[:item_kind].presence || "products").to_s
      merchandise_id = int_or_nil(@config[:merchandise_id] || @scenario.merchandise_id)
      variant_id = int_or_nil(@config[:variant_id])
      course_id = int_or_nil(@config[:course_id])
      raise Error, "SubscStore merchandise_id is missing" if merchandise_id.blank? && item_kind == "products"
      raise Error, "SubscStore course_id is missing" if course_id.blank? && item_kind != "products"

      case item_kind
      when "regular_courses"
        {
          regular_courses: [
            {
              id: course_id,
              products: [{ id: merchandise_id, variant_id: variant_id, quantity: quantity }.compact]
            }.compact
          ]
        }
      when "distribution_courses"
        { distribution_courses: [{ id: course_id }] }
      else
        {
          products: [
            {
              id: merchandise_id,
              variant_id: variant_id,
              quantity: quantity
            }.compact
          ]
        }
      end
    end

    def shipment(address)
      delivery_date = parse_json(find_response("delivery_date")) || {}
      scheduled = delivery_date["value"] || delivery_date["scheduled_delivery_on"]
      shipping_method_id = @payment_config&.shop_shipping_method_id_for(find_response("delivery_method"))
      time_zone_id = @payment_config&.time_zone_id_for(
        find_response("delivery_time"),
        shipping_method_id: shipping_method_id
      )
      payload = {
        shop_shipping_method_id: shipping_method_id,
        time_zone_id: time_zone_id,
        shipping_address: address
      }
      if scheduled.present?
        payload[:scheduled_delivery_on] = scheduled
      else
        payload[:is_not_specified] = true
      end
      payload.compact
    end

    def credit_method_id
      @payment_config&.credit_payment_method_shop_id
    end

    def np_method_id
      @payment_config&.np_payment_method_shop_id
    end

    def zip_code(data_address)
      raw = data_address["post_code"].presence ||
            data_address["value_post_code"].presence ||
            "#{data_address['value_post_code_left']}#{data_address['value_post_code_right']}"
      raw.to_s.gsub("-", "")
    end

    def state_id(data_address)
      value = data_address["value_prefecture"] || data_address["prefecture"] || data_address["state_id"]
      return nil if value.blank?
      return value.to_i if value.to_s.match?(/\A\d+\z/)

      prefecture = Prefecture.find_by(name: value) || Prefecture.find_by(prefecture_jis_code: value.to_s.rjust(2, "0"))
      prefecture&.prefecture_jis_code&.to_i
    end

    def birthday_value(birthday)
      year = birthday["valueYear"] || birthday["year"]
      month = birthday["valueMonth"] || birthday["month"]
      day = birthday["valueDay"] || birthday["day"]
      return nil if year.blank? || month.blank? || day.blank?

      format("%04d-%02d-%02d", year.to_i, month.to_i, day.to_i)
    end

    def gender_shop_id(value)
      return nil if value.blank?
      return 1 if value.to_s.match?(/1|男/)
      return 2 if value.to_s.match?(/2|女/)

      int_or_nil(value)
    end

    def expire_month(value)
      value.to_i.to_s.rjust(2, "0") if value.present?
    end

    def expire_year(value)
      return nil if value.blank?

      year = value.to_s.gsub(/\D/, "")
      year.length >= 4 ? year[-2, 2] : year.rjust(2, "0")
    end

    def find_response(data_input_name)
      @conversations.detect { |c| c.data_input_name == data_input_name }&.value
    end

    def parse_json(value)
      return value if value.is_a?(Hash)
      return nil if value.blank?

      JSON.parse(value)
    rescue JSON::ParserError
      nil
    end

    def decode_jwt(value)
      return nil if value.blank?

      JWT.decode(value, SECRET_KEY)[0]["data"]
    rescue StandardError
      value
    end

    def int_or_nil(value)
      return nil if value.blank?

      value.to_i
    end
  end
end
