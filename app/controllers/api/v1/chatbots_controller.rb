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
    @page_access_token = params[:object] == 'instagram' ? Settings.webhook.page_instagram_access_token : Settings.webhook.page_facebook_access_token
    params[:entry].each do |entry|
      webhook_event = entry[:messaging][0]
      sender_psid = webhook_event[:sender][:id]

      if webhook_event[:message].present?
        handleMessage(sender_psid, webhook_event[:message]);
      elsif webhook_event[:postback].present?
        handlePostback(sender_psid, webhook_event[:postback]);
      end
    end
    render html: "EVENT_RECEIVED".html_safe
  end

  private

  def handleMessage(sender_psid, received_message)
    return if received_message[:text].blank?
    chatbot_manager = FacebookManager::ChatbotManager.new sender_psid
    messages = Message.where(received_message: received_message[:text])
    messages.each do |message|
      quick_replies = message.quick_replies.pluck(:title) if message.quick_reply?
      chatbot_manager.message = chatbot_manager.message_value
      chatbot_manager.quick_replies = chatbot_manager.quick_replies
      chatbot_manager.call_graph_api
    end
  end
end
