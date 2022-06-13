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
    return head 404 unless params[:object] === 'page'
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
    if received_message[:text]
      response = {
        "text": "You sent the message: #{received_message[:text]}. Now send me an image!"
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

    post_request "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYoYLoNogABAGV3nuNx1ioF2xerZBWOrmekKzIPycWc2GK72ZBJY0umEntnoQRPYixG6sZCs1MgF2JpE4J9xOMvL4Ujg3smmcnqsurn7eyRYrPI17RU350vjm3aG4mU2H6ZCQ0mM3DuhXPPDFvg4lhQ7amsPcGM5fXiyQiaE7N6xwMZC20Om8EmRSekZA9iAZD", request_body
  end

  def post_request url, data
    require 'uri'
    require 'net/http'
    uri = URI(url)
    res = Net::HTTP.post_form(uri, data)
    res.body
  end
end
