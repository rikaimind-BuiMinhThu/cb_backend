module FacebookManager
  class ChatbotManager
    attr_accessor :message, :sender_psid, :quick_replies

    def initialize(sender_psid, message = nil, quick_replies = [])
      @message = message
      @sender_psid = sender_psid
      @quick_replies = quick_replies
    end

    def call_graph_api
      text_sent_to_user = @message.present? ? @message : "Hello! Welcome to the instagram chatbot!"
      response = {
        "text": text_sent_to_user
      }
      request_body = {
        "recipient": {
          "id": @sender_psid
        },
        "message": response
      }
      request_body["quick_replies"] = []
      quick_replies.each do |quick_reply|
        request_body["quick_replies"].push {"content_type": "text", title: quick_reply}
      end
      post_request "https://graph.facebook.com/v2.6/me/messages?access_token=#{@page_access_token}", request_body
    end

    private

    def post_request url, data
      require 'uri'
      require 'net/http'
      uri = URI(url)
      res = Net::HTTP.post(uri, data.to_query)
    end
  end
end
