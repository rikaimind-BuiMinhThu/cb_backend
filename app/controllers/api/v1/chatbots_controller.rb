class Api::V1::ChatbotsController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  # respond_to :json

  VERIFY_TOKEN = "hahant".freeze

  def webhook
    mode = params['hub.mode'];
    token = params['hub.verify_token'];
    challenge = params['hub.challenge'];

    return head :forbidden unless mode && token

    return head :forbidden unless mode === 'subscribe' && token === VERIFY_TOKEN
    render html: challenge.html_safe
  end

  def webhook_callback
    return render json: {code: 2, message: "error"} unless params[:object] === 'page'
    params[:entry].each do |entry|
      webhook_event = entry[:messaging][0]
      sender_psid = webhook_event.sender.id

      if webhook_event[:message].present?
        handleMessage(sender_psid, webhook_event[:message]);
      elsif webhook_event[:postback].present?
        handlePostback(sender_psid, webhook_event[:postback]);
      end
    end
    render json: {code: 1, message: "EVENT_RECEIVED"}
  end

  private

  def handleMessage(sender_psid, received_message)
    if received_message[:text]
      response = {
        "text": "You sent the message: #{received_message.text}. Now send me an image!"
      }
    end
    callSendAPI(sender_psid, response);
  end

  def callSendAPI(sender_psid, response)
    request_body = {
      recipient: {
        id: sender_psid
      },
      message: response
    }

    post_request "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYoYLoNogABAJcctIYRWEmhNgWNu57dsjCptZC2ZCUqmZB4AvDJ4y5ihN6rcQZAhglsLbo4pwUq7fiWZAM1ZCtyPPxM06rpUdxVp75hDz9FihtKDNJnts3Lkae97Kss6AxyvcFR7Lk5ZBgarM0BEd21vZBm5zQr4BUILDCB7Cog2cSV5gvqooZCEZADy0bMosSSkZD", request_body
  end

  def post_request url, data
    require 'uri'
    require 'net/http'
    uri = URI(url)
    res = Net::HTTP.post_form(uri, data)
    res.body
  end
end
