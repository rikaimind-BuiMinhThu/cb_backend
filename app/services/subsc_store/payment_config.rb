module SubscStore
  class PaymentConfig
    def initialize(http_client)
      @http = http_client
    end

    def fetch
      @fetch ||= @http.get("/configs/payment_config")
    end

    def payment_method_shops
      @payment_method_shops ||= begin
        result = @http.get("/payment_method_shops")
        result["payment_method_shops"] || result["data"] || []
      end
    end

    def shop_shipping_methods
      @shop_shipping_methods ||= begin
        result = @http.get("/shop_shipping_methods")
        result["shop_shipping_methods"] || result["data"] || []
      end
    end

    def public_tokenize_config
      config = fetch
      {
        zeus_ip_code: config["zeus_ip_code"],
        credit_card_script_path: config["credit_card_script_path"],
        is_zeus_using_security_code: config["is_zeus_using_security_code"]
      }
    end

    def credit_payment_method_shop_id
      find_payment_method_shop_id(/zeus|クレジット|credit/i)
    end

    def np_payment_method_shop_id
      find_payment_method_shop_id(/np|後払/i)
    end

    def default_shop_shipping_method_id
      item_id(Array(shop_shipping_methods).first)
    end

    def shop_shipping_method_id_for(delivery_method)
      methods = Array(shop_shipping_methods)
      text = normalize_choice(delivery_method)
      if text.present?
        match = methods.find { |item| labels_for(item).any? { |label| choice_matches?(label, text) } }
        found = item_id(match)
        return found if found.present?
      end

      default_shop_shipping_method_id
    end

    def time_zone_id_for(delivery_time, shipping_method_id: nil)
      text = normalize_choice(delivery_time)
      return nil if text.blank?

      methods = Array(shop_shipping_methods)
      preferred = methods.find { |item| item_id(item).to_i == shipping_method_id.to_i } if shipping_method_id.present?
      [preferred, *methods].compact.each do |method|
        Array(time_zones_for(method)).each do |zone|
          found = item_id(zone)
          return found if found.present? && labels_for(zone).any? { |label| choice_matches?(label, text) }
        end
      end

      nil
    end

    private

    def find_payment_method_shop_id(pattern)
      shop = Array(payment_method_shops).find do |item|
        labels_for(item).join(" ").match?(pattern)
      end
      item_id(shop)
    end

    def time_zones_for(method)
      hash = indifferent(method)
      hash["time_zones"] || hash["time_zone_shops"] || hash["time_zone"] ||
        hash.dig("shop_shipping_method", "time_zones") || []
    end

    def labels_for(item)
      hash = indifferent(item)
      [
        hash["id"],
        hash["name"],
        hash["label"],
        hash["title"],
        hash["payment_method_name"],
        hash.dig("payment_method", "name")
      ].compact.map(&:to_s)
    end

    def item_id(item)
      return nil if item.blank?

      hash = indifferent(item)
      hash["id"] || hash[:id]
    end

    def normalize_choice(value)
      return "" if value.blank?
      return value.to_s.strip unless value.is_a?(String)

      parsed = JSON.parse(value)
      if parsed.is_a?(Hash)
        parsed = parsed.with_indifferent_access
        return (parsed[:value] || parsed[:label] || parsed[:name] || parsed[:id] || value).to_s.strip
      end

      parsed.to_s.strip
    rescue JSON::ParserError
      value.to_s.strip
    end

    def choice_matches?(label, text)
      left = label.to_s.strip
      right = text.to_s.strip
      return false if left.blank? || right.blank?

      left == right || left.include?(right) || right.include?(left)
    end

    def indifferent(item)
      return {}.with_indifferent_access if item.blank?
      return item.with_indifferent_access if item.respond_to?(:with_indifferent_access)

      { "name" => item }.with_indifferent_access
    end
  end
end
