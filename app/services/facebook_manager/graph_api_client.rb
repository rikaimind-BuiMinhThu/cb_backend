module FacebookManager
  class GraphApiClient
    BASE_URL = Settings.facebook.sdk.url + Settings.facebook.sdk.version

    def initialize(access_token = nil)
      @access_token = access_token
    end

    def get(path, params = {})
      raw = HttpManager.new(build_url(path, params)).get_request
      normalize_response(raw)
    end

    def post(path, body = {}, params = {})
      raw = HttpManager.new(build_url(path, params), body).post_request
      normalize_response(raw)
    end

    def delete(path, params = {}, body = {})
      raw = HttpManager.new(build_url(path, params), body).delete_request
      normalize_response(raw)
    end

    def self.base_url
      BASE_URL
    end

    private

    def build_url(path, params)
      normalized_path = path.to_s.sub(%r{^/}, '')
      query_params = params.dup
      query_params[:access_token] = @access_token if @access_token.present?
      "#{BASE_URL}/#{normalized_path}?#{URI.encode_www_form(flatten_params(query_params))}"
    end

    def flatten_params(params)
      params.each_with_object({}) do |(key, value), result|
        result[key] = value.is_a?(Array) ? value.to_json : value
      end
    end

    def normalize_response(raw)
      return { success: false, data: nil, error: { message: 'Empty response' } } if raw.nil?

      if raw['error'].present?
        {
          success: false,
          data: raw,
          error: {
            code: raw['error']['code'],
            message: raw['error']['message'],
            type: raw['error']['type']
          }
        }
      else
        { success: true, data: raw, error: nil }
      end
    end
  end
end
