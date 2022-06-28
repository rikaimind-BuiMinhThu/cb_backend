module FacebookManager
  class ChatbotManager
    attr_accessor :message, :sender_psid
    attr_reader :platform

    def initialize(sender_psid, platform = 'instagram', message = nil)
      @platform = platform
      @message = message
      @sender_psid = sender_psid
    end

    def call_graph_api
      page_access_token = @platform == 'instagram' ? Settings.webhook.page_instagram_access_token : Settings.webhook.page_facebook_access_token
      send_message_to_user(page_access_token)
      send_image_to_user(page_access_token)
    end

    private

    def send_message_to_user page_access_token
      return if @message&.message_value.blank? && @message&.img_value&.url.present?
      text_sent_to_user = (@message&.message_value.blank? && @message&.img_value&.url.blank?) ? "Hello! Welcome to the instagram chatbot!" : @message.message_value
      response = {
        "text": text_sent_to_user
      }
      request_body = {
        "recipient": {
          "id": @sender_psid
        },
        "message": response
      }
      quick_replies = @message&.quick_replies&.pluck(:title)
      if quick_replies.present?
        request_body[:message][:quick_replies] = []
        @quick_replies.each do |quick_reply|
          request_body[:message][:quick_replies].push({
            "content_type": "text",
            "title": quick_reply[0, 19],
            "payload": "OK"
          })
        end
      end
      Rails.logger.debug(request_body)
      a = HttpManager.new("https://graph.facebook.com/v2.6/me/messages?access_token=#{page_access_token}", request_body).post_request
      Rails.logger.debug(a)
    end

    def send_image_to_user page_access_token
      return if @message&.img_value&.url.blank?
      response = {
        "attachment":{
          "type": "image",
          "payload":{
            "url": Settings.chatbot_domain + @message.img_value.url,
            "is_reusable": true
          }
        }
      }
      request_body = {
        "recipient": {
          "id": @sender_psid
        },
        "message": response
      }
      Rails.logger.debug(request_body)
      a = HttpManager.new("https://graph.facebook.com/v2.6/me/messages?access_token=#{page_access_token}", request_body).post_request
      Rails.logger.debug(a)
      Rails.logger.debug(JSON.parse(a.body))
    end

  end
end
