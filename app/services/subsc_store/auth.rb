require "faraday"
require "json"

module SubscStore
  class Auth
    def initialize(client)
      @client = client
    end

    def access_token
      if @client.use_subsc_store_mock?
        body = MockResponse.body_for(@client, :post, "/external_cooperation/access_tokens")
        return body["access_token"] || body.dig("data", "access_token") || "mock_access_token"
      end

      raise Error, "client_id is blank" if @client.client_id.blank?
      raise Error, "client_secret is blank" if @client.client_secret.blank?

      response = Faraday.post(token_url) do |req|
        req.headers["Content-Type"] = "application/json"
        req.options.timeout = 30
        req.body = JSON.generate(
          client_id: @client.client_id,
          client_secret: @client.client_secret
        )
      end

      parsed = parse_body(response.body)
      token = parsed["access_token"] || parsed.dig("data", "access_token")
      unless response.success? && token.present?
        raise Error.new("Failed to issue SubscStore access token", status: response.status, body: parsed)
      end
      token
    end

    private

    def parse_body(body)
      return {} if body.blank?

      JSON.parse(body)
    rescue JSON::ParserError
      { "raw" => body }
    end

    def token_url
      host = HttpClient.normalize_host(@client.shop_url)
      raise Error, "shop_url is blank" if host.blank?

      "https://#{host}/api/v1/external_cooperation/access_tokens"
    end
  end
end
