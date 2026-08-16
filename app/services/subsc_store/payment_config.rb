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
      method = Array(shop_shipping_methods).first
      return nil if method.blank?

      method["id"] || method[:id]
    end

    private

    def find_payment_method_shop_id(pattern)
      shop = Array(payment_method_shops).find do |item|
        name = [
          item["name"],
          item["payment_method_name"],
          item.dig("payment_method", "name"),
          item["label"]
        ].compact.join(" ")
        name.match?(pattern)
      end
      shop && (shop["id"] || shop[:id])
    end
  end
end
