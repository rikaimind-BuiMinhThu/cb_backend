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
        return head 404 if InstagramAccount.find_by(ig_id: sender_psid).present?

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

    usage_type = message_bag_type.split("bag")[0] + "received"
    instagram_user = create_instagram_user(sender_psid, usage_type, received_message[:text], instagram_account, media_id, nil)
    chatbot_manager = FacebookManager::ChatbotManager.new sender_psid, instagram_account, params[:object]
    return if instagram_user.pending_message&.free_input&.need_pending_check? && !check_user_message(instagram_user, received_message[:text], chatbot_manager)

    need_pending = instagram_user.pending_message&.free_input&.need_pending_check?

    if need_pending
      message_bags = MessageBag.where(id: instagram_user.pending_message)
      message_bags.each do |message_bag|
        messages = message_bag&.messages
        messages.each do |message|
          chatbot_manager.message = message
          chatbot_manager.message_type = message_bag_type
          chatbot_manager.call_graph_api
        end
      end
    end

    if received_message[:text].include?('support') && message_bag_type == "dm_bag" && !need_pending
      PageMailer.request_support_email(instagram_account.user).deliver
      chatbot_manager.payload = "We will send supporter to help you. Please wait!"
      chatbot_manager.call_postback_api
      SupportingUser.create instagram_account: instagram_account, sender_id: sender_psid
      return
    end

    if need_pending
      message_bags = [instagram_user.pending_message.message_bag]
    else
      message_bags = MessageBag.where(id: find_message_bag_ids(instagram_account, message_bag_type, received_message[:text]))
    end
    instagram_user.update(pending_message_id: nil)
    message_bags.each do |message_bag|
      messages = message_bag&.messages
      messages = messages.where("id > ?", instagram_user.pending_message.id) if need_pending
      messages.each do |message|
        return if instagram_user.pending_message.present?
        chatbot_manager.message = message
        chatbot_manager.message_type = message_bag_type
        chatbot_manager.call_graph_api
      end
    end
  end

  def handlePostback(sender_psid, ig_id, postback)
    return if postback[:payload].blank?
    postback_payload = JSON.parse(postback[:payload]).deep_symbolize_keys
    instagram_account = InstagramAccount.find_by(ig_id: ig_id)
    chatbot_manager = FacebookManager::ChatbotManager.new sender_psid, instagram_account, params[:object]

    instagram_user = create_instagram_user(sender_psid, "dm_received", postback[:title], instagram_account, nil, postback_payload[:message_button_id])
    return if instagram_user.pending_message&.free_input&.need_pending_check? && !check_user_message(instagram_user, received_message[:text], chatbot_manager)

    message_bag = MessageBag.find_by(id: postback_payload[:message_bag_id])
    return if message_bag&.message_group&.user_id != instagram_account.user_id

    messages = message_bag&.messages
    messages.each do |message|
      chatbot_manager.message = message
      chatbot_manager.message_type = "dm_bag"
      chatbot_manager.call_graph_api
    end
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

  def create_instagram_user(sender_psid, usage_type, content, instagram_account, media_id, message_button_id)
    ActiveRecord::Base.transaction do
      instagram_user = InstagramUser.find_or_create_by(instagram_id: sender_psid, instagram_account: instagram_account)
      instagram_user_query = HttpManager.new("https://graph.facebook.com/v14.0/#{sender_psid}?fields=name,username,follower_count,is_user_follow_business,is_business_follow_user&access_token=#{instagram_account.page_access_token}").get_request
      instagram_user.update(username: instagram_user_query["username"], full_name: instagram_user_query["name"], follower_count: instagram_user_query["follower_count"], is_verified_user: instagram_user_query["is_verified_user"], is_user_follow_business: instagram_user_query["is_user_follow_business"], is_business_follow_user: instagram_user_query["is_business_follow_user"])

      if message_button_id.present?
        message_button_labels = MessageButton.find_by(id: message_button_id)&.message_button_labels
        if message_button_labels.present?
          message_button_labels.each do |message_button_label|
            InstagramUserLabel.find_or_create_by(message_button_label: message_button_label, instagram_user: instagram_user)
          end
        end
      end

      chatbot_usage = ChatbotUsage.new(instagram_user: instagram_user, usage_type: usage_type, content: content, instagram_account: instagram_account, media_id: media_id)
      if ChatbotUsage.where(media_id: media_id).where.not(media_start_at: nil).blank?
        media_query = HttpManager.new("https://graph.facebook.com/#{media_id}?fields=id,timestamp&access_token=#{instagram_account.page_access_token}").get_request
        chatbot_usage.media_start_at = media_query["timestamp"].to_datetime if media_query["timestamp"].present?
      end
      chatbot_usage.save
    end
    instagram_user
  end

  def check_user_message(instagram_user, received_message_text, chatbot_manager)
    return false if received_message_text.blank?

    ActiveRecord::Base.transaction do
      if instagram_user.pending_message&.free_input&.format_check_email? && instagram_user.update(email: received_message_text)
        instagram_user.update(pending_message_id: nil)
        return true
      end
      if instagram_user.pending_message&.free_input&.format_check_phone_number? && instagram_user.update(phone_number: received_message_text)
        instagram_user.update(pending_message_id: nil)
        return true
      end
    end

    chatbot_manager.payload = instagram_user.pending_message&.free_input&.format_check_message
    chatbot_manager.call_postback_api
    return false
  end
end
