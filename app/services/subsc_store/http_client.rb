require "faraday"
require "json"

module SubscStore
  class HttpClient
    def self.normalize_host(shop_url)
      host = shop_url.to_s.strip
      host = host.sub(%r{\Ahttps?://}i, "")
      host = host.sub(%r{/+\z}, "")
      host = host.sub(%r{/admin\z}i, "")
      host
    end

    def initialize(client)
      @client = client
      return if client.use_subsc_store_mock?

      host = self.class.normalize_host(client.shop_url)
      raise Error, "shop_url is blank" if host.blank?

      @base_url = "https://#{host}/api/v1"
    end

    def post(path, body = {})
      request(:post, path, body)
    end

    def put(path, body = {})
      request(:put, path, body)
    end

    def patch(path, body = {})
      request(:patch, path, body)
    end

    def get(path, params = {})
      request(:get, path, nil, params)
    end

    private

    def request(method, path, body = nil, params = {})
      return MockResponse.body_for(@client, method, path) if @client.use_subsc_store_mock?

      response = connection.public_send(method) do |req|
        req.url path
        req.params.update(params) if params.present?
        req.body = JSON.generate(body) unless body.nil? || method == :get
      end

      parsed = parse_body(response.body)
      unless response.success?
        raise Error.new(
          "SubscStore API #{method.upcase} #{path} failed (#{response.status})",
          status: response.status,
          body: parsed
        )
      end
      parsed
    end

    def connection
      @connection ||= Faraday.new(url: @base_url) do |f|
        f.headers["Content-Type"] = "application/json"
        f.headers["Authorization"] = "Bearer #{access_token}"
        f.options.timeout = 60
        f.options.open_timeout = 15
        f.adapter Faraday.default_adapter
      end
    end

    def access_token
      @access_token ||= Auth.new(@client).access_token
    end

    def parse_body(body)
      return {} if body.blank?

      JSON.parse(body)
    rescue JSON::ParserError
      { "raw" => body }
    end
  end
end
