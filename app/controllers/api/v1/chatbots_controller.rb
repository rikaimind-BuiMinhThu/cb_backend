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
          message_bag_type = "story_comment_bag" if webhook_event[:message][:reply_to].present? && webhook_event[:message][:reply_to][:story].present?

          handleMessage(sender_psid, entry[:id], webhook_event[:message], message_bag_type, "")
        elsif webhook_event[:postback].present?
          handlePostback(sender_psid, entry[:id], webhook_event[:postback])
        end
      elsif entry[:changes].present?
        webhook_event = entry[:changes][0][:value]
        comment_id = webhook_event[:from][:id]
        media_id = webhook_event[:media][:id]
        if entry[:changes][0][:field] == "comments"
          message_bag_type = "post_comment_bag"
        elsif entry[:changes][0][:field] == "live_comments"
          message_bag_type = "live_comment_bag"
        end
        return if message_bag_type.blank?
        handleMessage(comment_id, entry[:id], webhook_event, message_bag_type, media_id)
      end
    end
    render html: "EVENT_RECEIVED".html_safe
  end

  private

  def handleMessage(sender_psid, ig_id, received_message, message_bag_type, media_id)
    return if received_message[:text].blank?
    instagram_account = InstagramAccount.find_by(ig_id: ig_id)
    return if instagram_account.blank?
    return if SupportingUser.find_by(instagram_account: instagram_account, sender_id: sender_psid).present?
    chatbot_manager = FacebookManager::ChatbotManager.new sender_psid, instagram_account, params[:object]
    if received_message[:text].include?('support') && message_bag_type == "dm_bag"
      PageMailer.request_support_email(instagram_account.user).deliver
      chatbot_manager.payload = "We will send supporter to help you. Please wait!"
      chatbot_manager.call_postback_api
      SupportingUser.create instagram_account: instagram_account, sender_id: sender_psid
      return
    end
    usage_type = message_bag_type.split("bag")[0] + "received"
    if ChatbotUsage.where(media_id: media_id).where.not(media_start_at: nil).blank?
      media_query = HttpManager.new("https://graph.facebook.com/#{media_id}?fields=id,timestamp&access_token=#{instagram_account.page_access_token}").get_request
      chatbot_usage = ChatbotUsage.new(sender_id: sender_psid, usage_type: usage_type, content: received_message[:text], instagram_account: instagram_account,media_id: media_id)
      chatbot_usage.media_start_at = media_query["timestamp"].to_datetime if media_query["timestamp"].present?
      chatbot_usage.save
    else
      ChatbotUsage.create(sender_id: sender_psid, usage_type: usage_type, content: received_message[:text], instagram_account: instagram_account,media_id: media_id)
    end
    message_bags = MessageBag.where(id: find_message_bag_ids(instagram_account, message_bag_type, received_message[:text]))
    message_bags.each do |message_bag|
      messages = message_bag&.messages
      messages.each do |message|
        # quick_replies = message.quick_replies.pluck(:title)
        chatbot_manager.message = message
        chatbot_manager.message_type = message_bag_type
        # chatbot_manager.quick_replies = quick_replies
        chatbot_manager.call_graph_api
      end
    end
  end

  def handlePostback(sender_psid, ig_id, postback)
    return if postback[:payload].blank?
    instagram_account = InstagramAccount.find_by(ig_id: ig_id)
    chatbot_manager = FacebookManager::ChatbotManager.new sender_psid, instagram_account, params[:object]
    chatbot_manager.payload = postback[:payload]
    chatbot_manager.call_postback_api
  end

  def find_message_bag_ids(instagram_account, message_bag_type, received_message_text)
    message_bag_ids = []
    if message_bag_type == "dm_bag"
      keywords = KeywordSetting.where(instagram_account: instagram_account, is_active: true, is_dm: true).each do |keyword_setting|
        keyword_setting.keyword.split("|").each {|keyword| message_bag_ids.push(keyword_setting.message_bag_id) if received_message_text.downcase.include?(keyword.downcase)}
      end
    else
      status_type = instagram_account.send(message_bag_type + "_status")
      if status_type == "direct_message"
        message_bag_ids.push(instagram_account.send(message_bag_type + "_id"))
      elsif status_type == "keyword"
        keywords = KeywordSetting.where(instagram_account: instagram_account, is_active: true, "is_" + message_bag_type.split("_bag")[0] => true).each do |keyword_setting|
          keyword_setting.keyword.split("|").each {|keyword| message_bag_ids.push(keyword_setting.message_bag_id) if received_message_text.downcase.include?(keyword.downcase)}
        end
      end
    end
    message_bag_ids
  end
end
