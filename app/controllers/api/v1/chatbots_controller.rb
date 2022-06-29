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
          handleMessage(sender_psid, webhook_event[:message], "message")
        elsif webhook_event[:postback].present?
          handlePostback(sender_psid, webhook_event[:postback])
        end
      elsif entry[:changes].present?
        webhook_event = entry[:changes][0][:value]
        comment_id = webhook_event[:id]
        handleMessage(comment_id, webhook_event, "comment")
      end
    end
    render html: "EVENT_RECEIVED".html_safe
  end

  private

  def handleMessage(sender_psid, received_message, message_type)
    return if received_message[:text].blank?
    chatbot_manager = FacebookManager::ChatbotManager.new sender_psid, params[:object]
    messages = Message.where(received_message: received_message[:text])
    messages.each do |message|
      # quick_replies = message.quick_replies.pluck(:title)
      chatbot_manager.message = message
      chatbot_manager.message_type = message_type
      # chatbot_manager.quick_replies = quick_replies
      chatbot_manager.call_graph_api
    end
    chatbot_manager.call_graph_api if messages.length == 0
  end

  def handlePostback(sender_psid, postback)
    return if postback[:payload].blank?
    chatbot_manager = FacebookManager::ChatbotManager.new sender_psid, params[:object]
    chatbot_manager.payload = postback[:payload]
    chatbot_manager.call_postback_api
  end
end
