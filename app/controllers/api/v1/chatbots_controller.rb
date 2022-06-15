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
    query_field = params[:object] == 'instagram' ? "name,username,profile_pic" : "first_name,last_name,profile_pic"
    query = {
      fields: query_field,
      access_token: @page_access_token
    }
    user_info = get_request "https://graph.facebook.com/#{sender_psid}", query
    user_full_name = params[:object] == 'instagram' ? user_info["name"] : user_info["first_name"] + " " + user_info["last_name"]
    if received_message[:text]
      message = Message.where(message_key: received_message[:text]).last
      text_sent_to_user = message.present? ? message.message_value : "Hello #{user_full_name}! Welcome to the instagram chatbot!"
      response = {
        "text": text_sent_to_user
      }
    end
    callSendAPI(sender_psid, response);
  end

  def callSendAPI(sender_psid, response)
    request_body = {
      "recipient": {
        "id": sender_psid
      },
      "message": response
    }
    a = post_request "https://graph.facebook.com/v2.6/me/messages?access_token=#{@page_access_token}", request_body
    puts a
  end

  def post_request url, data
    require 'uri'
    require 'net/http'
    uri = URI(url)
    res = Net::HTTP.post(uri, data.to_query)
  end

  def get_request url, query
    require 'uri'
    require 'net/http'
    uri = URI(url + "?" + query.to_query)
    res = Net::HTTP.get(uri)
    JSON.parse(res)
  end
end
