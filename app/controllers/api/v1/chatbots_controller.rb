class Api::V1::ChatbotsController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  # respond_to :json

  VERIFY_TOKEN = Settings.webhook.verify_token.freeze

  def webhook
    mode = params['hub.mode'];
    token = params['hub.verify_token'];
    challenge = params['hub.challenge'];

    return head :forbidden unless mode && token

    return head :forbidden unless mode === 'subscribe' && token === VERIFY_TOKEN
    render html: challenge.html_safe
  end

  def webhook_callback
    return head 404 unless ['page', 'instagram'].include? params[:object]

    params[:entry].each do |entry|
      if entry[:messaging].present?
        webhook_event = entry[:messaging][0]
        sender_psid = webhook_event[:sender][:id]

        if webhook_event[:message].present?
          message_bag_type = "dm_bag"
          if webhook_event[:message][:reply_to].present? && webhook_event[:message][:reply_to][:story].present?
            message_bag_type = "story_comment_bag"
          end
          handleMessage(sender_psid, entry[:id], webhook_event[:message], message_bag_type)
        elsif webhook_event[:postback].present?
          handlePostback(sender_psid, entry[:id], webhook_event[:postback])
        end
      elsif entry[:changes].present?
        webhook_event = entry[:changes][0][:value]
        comment_id = webhook_event[:from][:id]
        if entry[:changes][0][:field] == "comments"
          message_bag_type = "post_comment_bag"
        elsif entry[:changes][0][:field] == "live_comments"
          message_bag_type = "live_comment_bag"
        end
        return if message_bag_type.blank?
        handleMessage(comment_id, entry[:id], webhook_event, message_bag_type)
      end
    end
    render html: "EVENT_RECEIVED".html_safe
  end

  private

  def handleMessage(sender_psid, ig_id, received_message, message_bag_type)
    return if received_message[:text].blank?
    instagram_account = InstagramAccount.find_by(ig_id: ig_id)
    return if instagram_account.blank?
    chatbot_manager = FacebookManager::ChatbotManager.new sender_psid, params[:object]
    message_bag = instagram_account.send(message_bag_type) if instagram_account.send(message_bag_type + "_status?").present?
    messages = message_bag&.messages&.where(received_message: received_message[:text])
    return chatbot_manager.call_graph_api if messages.blank?
    messages.each do |message|
      # quick_replies = message.quick_replies.pluck(:title)
      chatbot_manager.message = message
      chatbot_manager.message_type = message_bag_type
      # chatbot_manager.quick_replies = quick_replies
      chatbot_manager.call_graph_api
    end
  end

  def handlePostback(sender_psid, ig_id, postback)
    return if postback[:payload].blank?
    chatbot_manager = FacebookManager::ChatbotManager.new sender_psid, params[:object]
    chatbot_manager.payload = postback[:payload]
    chatbot_manager.call_postback_api
  end
end
