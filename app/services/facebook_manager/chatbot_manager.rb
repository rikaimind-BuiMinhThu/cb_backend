module FacebookManager
  class ChatbotManager
    attr_accessor :message, :sender_psid, :payload, :message_type, :instagram_account, :instagram_user
    attr_reader :platform

    def initialize(sender_psid, instagram_account, instagram_user, platform = 'instagram', message = nil, payload = nil, message_type = 'message')
      @platform = platform
      @message = message
      @sender_psid = sender_psid
      @instagram_account = instagram_account
      @instagram_user = instagram_user
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

    def graph_client(page_access_token)
      GraphApiClient.new(page_access_token)
    end

    def send_message_to_user(page_access_token)
      return if @message&.message_type == "past_post"
      return if @message&.message_value.blank?

      text_sent_to_user = @message.message_value

      if @message.message_buttons.present?
        buttons = []
        @message.message_buttons.each do |message_button|
          if message_button.web_url?
            button_url = add_params_to_url(message_button.content, instagram_user, @message)
            buttons.push({
              "type": "web_url",
              "title": message_button.title,
              "url": button_url
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
        text_sent_to_user = add_params_to_url(text_sent_to_user, instagram_user, @message) if HttpManager.new(text_sent_to_user).uri?
        response = {
          "text": text_sent_to_user
        }
      end

      request_body = build_message_request_body(response)
      Rails.logger.debug(request_body)
      message_response = post_message(page_access_token, request_body)
      Rails.logger.debug(message_response)
      usage_type = @message_type.split("bag")[0] + "sent"
      create_instagram_log(@sender_psid, usage_type, text_sent_to_user, @instagram_account, nil, nil) if message_response.dig(:data, "recipient_id").present?
    end

    def send_image_to_user(page_access_token)
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
      request_body = build_message_request_body(response)
      Rails.logger.debug(request_body)
      message_response = post_message(page_access_token, request_body)
      Rails.logger.debug(message_response)
      usage_type = @message_type.split("bag")[0] + "sent"
      create_instagram_log(@sender_psid, usage_type, Settings.chatbot_domain + @message.img_value.url, @instagram_account, nil, nil) if message_response.dig(:data, "recipient_id").present?
    end

    def send_payload_to_user(page_access_token)
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
      message_response = post_message(page_access_token, request_body)
      Rails.logger.debug(message_response)
      create_instagram_log(@sender_psid, "dm_sent", @payload, @instagram_account, nil, nil) if message_response.dig(:data, "recipient_id").present?
    end

    def share_post_to_user(page_access_token)
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
      message_response = post_message(page_access_token, request_body)
      Rails.logger.debug(message_response)
      create_instagram_log(@sender_psid, "dm_sent", @message.message_value, @instagram_account, nil, nil) if message_response.dig(:data, "recipient_id").present?
    end

    def build_message_request_body(response)
      if ['comments', 'live_comments'].include?(@message_type)
        {
          "recipient": {
            "comment_id": @sender_psid
          },
          "message": response
        }
      else
        {
          "recipient": {
            "id": @sender_psid
          },
          "message": response
        }
      end
    end

    def post_message(page_access_token, request_body)
      graph_client(page_access_token).post('me/messages', request_body)
    end

    def create_instagram_log(sender_psid, usage_type, content, instagram_account, media_id, message_button_id)
      ActiveRecord::Base.transaction do
        instagram_user = InstagramUser.find_or_create_by!(instagram_id: sender_psid, instagram_account: instagram_account)
        profile_result = graph_client(instagram_account.page_access_token).get(
          sender_psid.to_s,
          fields: 'name,username,follower_count,is_user_follow_business,is_business_follow_user'
        )
        if profile_result[:success]
          instagram_user_query = profile_result[:data]
          instagram_user.update!(
            username: instagram_user_query["username"],
            full_name: instagram_user_query["name"],
            follower_count: instagram_user_query["follower_count"],
            is_verified_user: instagram_user_query["is_verified_user"],
            is_user_follow_business: instagram_user_query["is_user_follow_business"],
            is_business_follow_user: instagram_user_query["is_business_follow_user"],
            instagram_account: instagram_account
          )
        end

        chatbot_usage = ChatbotUsage.new(instagram_user: instagram_user, usage_type: usage_type, content: content, media_id: media_id, instagram_account: instagram_account)
        if ChatbotUsage.where(media_id: media_id).where.not(media_start_at: nil).blank? && media_id.present?
          media_result = graph_client(instagram_account.page_access_token).get(media_id.to_s, fields: 'id,timestamp')
          chatbot_usage.media_start_at = media_result.dig(:data, "timestamp").to_datetime if media_result.dig(:data, "timestamp").present?
        end
        chatbot_usage.save!
        ChatbotUsageGroup.create(chatbot_usage: chatbot_usage, message_bag: @message.message_bag, message_group: @message.message_bag.message_group)

        instagram_user.update!(pending_message: @message) if @message&.free_input&.present?
      end
    end

    def add_params_to_url(content, instagram_user, message)
      content = content.include?('?') ? content + "&instagram_user=" + instagram_user.id.to_s : content + "?instagram_user=" + instagram_user.id.to_s
      content += "&message_bag_id=" + message.message_bag.id.to_s
    end
  end
end
