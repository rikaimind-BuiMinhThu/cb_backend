class Api::V1::ChatbotsController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  respond_to :json

  VERIFY_TOKEN = "hahant".freeze

  def webhook
    mode = params['hub.mode'];
    token = params['hub.verify_token'];
    challenge = params['hub.challenge'];

    return render json: {code: 2, message: "error"} unless mode && token

    return render json: {code: 2, message: "error"} unless mode === 'subscribe' && token === VERIFY_TOKEN
    render json: {code: 1, message: "OK"}
  end

  def webhook_callback
    return render json: {code: 2, message: "error"} unless params[:object] === 'page'
    params[:entry].each do |entry|
      webhook_event = entry[:messaging][0]
    end
    render json: {code: 1, message: "EVENT_RECEIVED"}
  end
end
