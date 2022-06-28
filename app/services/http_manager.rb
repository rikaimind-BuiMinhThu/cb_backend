class HttpManager
  require 'uri'
  require 'net/http'

  attr_reader :url, :data

  def initialize(url, data = {})
    @url = url
    @data = data
  end

  def get_request
    uri = URI.parse(@url)
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end

  def post_request
    uri = URI(@url)
    header = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
    request = Net::HTTP::Post.new(uri.request_uri, header)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request.body = @data.to_json
    response = http.request(request)
    response.body.present? ? JSON.parse(response.body) : nil
  end

  def delete_request
    uri = URI(@url)
    header = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
    request = Net::HTTP::Delete.new(uri.path)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request.body = @data.to_json
    response = http.request(request)
    response.body.present? ? JSON.parse(response.body) : nil
  end
end
