module FacebookManager
  class ChatbotManager
    attr_accessor :message, :sender_psid, :payload, :message_type, :instagram_account
    attr_reader :platform

    def initialize(sender_psid, instagram_account, platform = 'instagram', message = nil, payload = nil, message_type = 'message')
      @platform = platform
      @message = message
      @sender_psid = sender_psid
      @instagram_account = instagram_account
      @payload = payload
      @message_type = message_type
    end

    def call_graph_api
      page_access_token = @instagram_account.page_access_token
      send_message_to_user(page_access_token)
      send_image_to_user(page_access_token)
      share_post_to_user(page_access_token)
    end

    def call_postback_api
      page_access_token = @instagram_account.page_access_token
      send_payload_to_user(page_access_token)
    end

    private

    def send_message_to_user page_access_token
      return if @message&.message_type == "past_post"
      return if @message&.message_value.blank?
      text_sent_to_user =  @message.message_value

      if @message.message_buttons.present?
        buttons = []
        @message.message_buttons.each do |message_button|
          if message_button.web_url?
            buttons.push({
              "type": "web_url",
              "title": message_button.title,
              "url": message_button.content,
            })
          else
            payload_hash = {message_bag_id: message_button.message_bag_id, message_button_id: message_button.id}
            buttons.push({
              "type": "postback",
              "title": message_button.title,
              "payload": payload_hash.to_json,
            })
          end
        end

        response = {
          "attachment":{
            "type": "template",
            "payload":{
              "template_type": "generic",
              "elements": [
                {
                  "title": text_sent_to_user,
                  "buttons": buttons
                }
              ]
            }
          }
        }
      else
        response = {
          "text": text_sent_to_user
        }
      end

      if ['comments', 'live_comments'].include?(@message_type)
        request_body = {
          "recipient": {
            "comment_id": @sender_psid
          },
          "message": response
        }
      else
        request_body = {
          "recipient": {
            "id": @sender_psid
          },
          "message": response
        }
      end
      Rails.logger.debug(request_body)
      message_response = HttpManager.new("https://graph.facebook.com/v2.6/me/messages?access_token=#{page_access_token}", request_body).post_request
      Rails.logger.debug(message_response)
      usage_type = @message_type.split("bag")[0] + "sent"
      ChatbotUsage.create(sender_id: @sender_psid, usage_type: usage_type, content: text_sent_to_user, instagram_account: @instagram_account) if message_response["recipient_id"].present?
    end

    def send_image_to_user page_access_token
      return if @message&.img_value&.url.blank?
      response = {
        "attachment":{
          "type": "IMAGE",
          "payload":{
            "url": Settings.chatbot_domain + @message.img_value.url,
            "is_reusable": true
          }
        }
      }
      if ['comments', 'live_comments'].include?(@message_type)
        request_body = {
          "recipient": {
            "comment_id": @sender_psid
          },
          "message": response
        }
      else
        request_body = {
          "recipient": {
            "id": @sender_psid
          },
          "message": response
        }
      end
      Rails.logger.debug(request_body)
      message_response = HttpManager.new("https://graph.facebook.com/v2.6/me/messages?access_token=#{page_access_token}", request_body).post_request
      Rails.logger.debug(message_response)
      usage_type = @message_type.split("bag")[0] + "sent"
      ChatbotUsage.create(sender_id: @sender_psid, usage_type: usage_type, content: Settings.chatbot_domain + @message.img_value.url, instagram_account: @instagram_account) if message_response["recipient_id"].present?
    end

    def send_payload_to_user page_access_token
      return if @payload.blank?
      response = {
        "text": @payload
      }
      request_body = {
        "recipient": {
          "id": @sender_psid
        },
        "message": response
      }
      Rails.logger.debug(request_body)
      message_response = HttpManager.new("https://graph.facebook.com/v2.6/me/messages?access_token=#{page_access_token}", request_body).post_request
      Rails.logger.debug(message_response)
      ChatbotUsage.create(sender_id: @sender_psid, instagram_account: @instagram_account) if message_response["recipient_id"].present?
    end

    def share_post_to_user page_access_token
      return if @message&.message_value.blank? || @message.message_type != "past_post"
      request_body = {
        "recipient": {
          "id": @sender_psid
        },
        "message": {
          "attachment":{
            "type": "MEDIA_SHARE",
            "payload": {"id": @message.message_value}
          }
        }
      }
      Rails.logger.debug(request_body)
      message_response = HttpManager.new("https://graph.facebook.com/v14.0/me/messages?access_token=#{page_access_token}", request_body).post_request
      Rails.logger.debug(message_response)
      ChatbotUsage.create(sender_id: @sender_psid, instagram_account: @instagram_account) if message_response["recipient_id"].present?
    end
  end
end
