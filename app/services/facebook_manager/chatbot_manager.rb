module FacebookManager
  class ChatbotManager
    attr_accessor :message, :sender_psid, :quick_replies
    attr_reader :platform

    def initialize(sender_psid, platform = 'instagram', message = nil, quick_replies = [])
      @platform = platform
      @message = message
      @sender_psid = sender_psid
      @quick_replies = quick_replies
    end

    def call_graph_api
      page_access_token = @platform == 'instagram' ? Settings.webhook.page_instagram_access_token : Settings.webhook.page_facebook_access_token
      text_sent_to_user = @message.present? ? @message : "Hello! Welcome to the instagram chatbot!"
      response = {
        "text": text_sent_to_user,
        "quick_replies": []
      }
      request_body = {
        "recipient": {
          "id": @sender_psid
        },
        "message": response
      }
      quick_replies.each do |quick_reply|
        request_body[:message][:quick_replies].push({
          "content_type": "text",
          "title": quick_reply[0, 19],
          "payload": "OK"
        })
      end
      post_request "https://graph.facebook.com/v2.6/me/messages?access_token=#{page_access_token}", request_body
    end

    private

    def post_request url, data
      require 'uri'
      require 'net/http'
      uri = URI(url)
      header = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      request = Net::HTTP::Post.new(uri.request_uri, header)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request.body = data.to_json
      http.request(request)
    end
  end
end
