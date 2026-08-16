module SubscStore
  class Purchase
    def initialize(client)
      @client = client
      @http = HttpClient.new(client)
    end

    def payment_config
      @payment_config ||= PaymentConfig.new(@http)
    end

    def confirm(payload)
      @http.put("/purchase/confirm_order", payload)
    end

    def create(payload)
      @http.post("/purchase/create_order", payload)
    end

    def confirm_and_create(payload)
      confirm_result = confirm(payload)
      create_result = create(payload)
      {
        confirm: confirm_result,
        create: create_result,
        order_id: extract_order_id(create_result),
        order_uid: extract_order_uid(create_result),
        three_d_secure_params: extract_three_d_secure(create_result)
      }
    end

    def created_order_meta(create_result)
      {
        order_id: extract_order_id(create_result),
        order_uid: extract_order_uid(create_result),
        three_d_secure_params: extract_three_d_secure(create_result)
      }
    end

    def http
      @http
    end

    private

    def extract_order_id(result)
      result.dig("order", "id") || result["id"] || result.dig("data", "order", "id") || result.dig("data", "id")
    end

    def extract_order_uid(result)
      result.dig("order", "uid") || result["uid"] || result.dig("data", "order", "uid") || result.dig("data", "uid")
    end

    def extract_three_d_secure(result)
      result["three_d_secure_params"] || result.dig("order", "three_d_secure_params")
    end
  end
end
