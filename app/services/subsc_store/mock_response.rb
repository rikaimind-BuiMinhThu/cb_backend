module SubscStore
  class MockResponse
    DEFAULTS = {
      "access_tokens" => {
        "access_token" => "mock_access_token"
      },
      "payment_config" => {
        "zeus_ip_code" => "MOCK_IP",
        "credit_card_script_path" => "",
        "is_zeus_using_security_code" => true
      },
      "payment_method_shops" => {
        "payment_method_shops" => [
          { "id" => 1, "name" => "クレジットカード", "payment_method_name" => "credit" },
          { "id" => 2, "name" => "NP後払い", "payment_method_name" => "np" }
        ]
      },
      "shop_shipping_methods" => {
        "shop_shipping_methods" => [
          { "id" => 1, "name" => "通常配送" }
        ]
      },
      "confirm_order" => {
        "success" => true,
        "order" => {
          "total" => 5980,
          "tax_total" => 544,
          "charge_total" => 0,
          "coupon_adjustment_total" => 0,
          "rank_discount" => 0,
          "payment_method_shop_id" => 1,
          "client_address" => {
            "family_name" => "山田",
            "first_name" => "太郎",
            "family_name_kana" => "ヤマダ",
            "first_name_kana" => "タロウ",
            "email" => "taro@example.com",
            "tel" => "09012345678",
            "zip_code" => "1500001",
            "state_id" => 13,
            "city" => "渋谷区",
            "address" => "神宮前1-1-1",
            "building_name" => ""
          },
          "order_items" => {
            "products" => [
              { "quantity" => 1, "total_includes_tax" => 5480 }
            ]
          },
          "shipments" => [
            { "postage" => 500, "is_not_specified" => true }
          ],
          "credit_card" => {
            "masked_card_number" => "411111*******111",
            "brand" => "visa",
            "expire_month" => "12",
            "expire_year" => "30"
          }
        }
      },
      "create_order" => {
        "success" => true,
        "order" => {
          "id" => 900001,
          "uid" => "MOCK-ORDER-001"
        }
      },
      "change_order_items" => {
        "success" => true
      }
    }.freeze

    KEYS = DEFAULTS.keys.freeze

    def self.body_for(client, method, path)
      key = key_for(method, path)
      override = lookup(client&.mock_response_hash, key)
      parsed = parse_value(override)
      return deep_stringify(parsed) if parsed.present?

      DEFAULTS[key] || { "success" => true }
    end

    def self.key_for(_method, path)
      normalized = path.to_s.sub(%r{\Ahttps?://[^/]+}i, "")
      normalized = normalized.sub(%r{\A/api/v1}, "")
      normalized = "/#{normalized}" unless normalized.start_with?("/")

      return "access_tokens" if normalized.include?("access_tokens")
      return "payment_config" if normalized.include?("payment_config")
      return "payment_method_shops" if normalized.include?("payment_method_shops")
      return "shop_shipping_methods" if normalized.include?("shop_shipping_methods")
      return "confirm_order" if normalized.include?("confirm_order")
      return "create_order" if normalized.include?("create_order")
      return "change_order_items" if normalized.include?("change_order_items")

      nil
    end

    def self.lookup(hash, key)
      return nil if hash.blank? || key.blank?

      hash[key] || hash[key.to_sym]
    end

    def self.parse_value(value)
      return nil if value.blank?
      return JSON.parse(value) if value.is_a?(String)

      value
    rescue JSON::ParserError
      value
    end

    def self.deep_stringify(value)
      JSON.parse(JSON.generate(value.as_json))
    end
  end
end
