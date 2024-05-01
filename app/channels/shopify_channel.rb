class ShopifyChannel < ApplicationCable::Channel
  def subscribed
    stream_from "ShopifyChannel"
  end
end

