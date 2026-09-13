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

    Rails.logger.info(
      "[webhook] object=#{params[:object]} entries=#{params[:entry]&.size} " \
      "fields=#{params[:entry]&.flat_map { |e| e[:changes]&.map { |c| c[:field] } }&.compact}"
    )

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
    message_text = extract_message_text(received_message)
    return if message_text.blank?
    instagram_account = InstagramAccount.find_by(ig_id: ig_id)
    return if instagram_account.blank?

    usage_type = message_bag_type.split("bag")[0] + "received"
    instagram_user = create_instagram_user(sender_psid, usage_type, instagram_account, nil)
    chatbot_usage = create_chatbot_usage(instagram_user, usage_type, message_text, instagram_account, media_id)
    return if SupportingUser.find_by(instagram_account: instagram_account, instagram_user: instagram_user).present?
    chatbot_manager = FacebookManager::ChatbotManager.new sender_psid, instagram_account, instagram_user, params[:object]
    pending_message_id = instagram_user.pending_message_id
    return if !check_user_message(instagram_user, message_text, chatbot_manager)

    pending_message = Message.find_by(id: pending_message_id)

    if pending_message.present?
      message_bags = MessageBag.where(id: pending_message.message_bag.id)
    else
      message_bag_ids = find_message_bag_ids(instagram_account, message_bag_type, message_text)
      message_bags = MessageBag.where(id: message_bag_ids)
      message_bags = message_bags.order(Arel.sql("field(id, #{message_bag_ids.join(',')})")) if message_bag_ids.present?
    end
    message_bags = MessageBag.where(id: instagram_account.default_reply_bag_id) if message_bags.blank? && instagram_account.default_reply_bag_id.present?
    message_bags.each do |message_bag|
      ChatbotUsageGroup.create(chatbot_usage: chatbot_usage, message_bag: message_bag, message_group: message_bag.message_group)
      messages = message_bag&.messages&.order(:order_no)
      if pending_message.present?
        messages = if pending_message.order_no.present?
          messages.where("order_no > ?", pending_message.order_no)
        else
          messages.where("id > ?", pending_message.id)
        end
      end
      messages.each do |message|
        return if InstagramUser.find_by(id: instagram_user.id).pending_message.present?
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

    instagram_user = create_instagram_user(sender_psid, "dm_received", instagram_account, postback_payload[:message_button_id])
    chatbot_usage = create_chatbot_usage(instagram_user, "dm_received", postback[:title], instagram_account, nil)
    chatbot_manager = FacebookManager::ChatbotManager.new sender_psid, instagram_account, instagram_user, params[:object]
    # return if instagram_user.pending_message&.free_input&.need_pending_check? && !check_user_message(instagram_user, received_message[:text], chatbot_manager)

    if postback_payload[:is_support].blank?
      pending_message_id = instagram_user.pending_message_id
      return if !check_user_message(instagram_user, postback[:title], chatbot_manager)

      pending_message = Message.find_by(id: pending_message_id)

      message_bag = pending_message.present? ? MessageBag.find_by(id: Message.find_by(id: pending_message.id).message_bag.id) : MessageBag.find_by(id: postback_payload[:message_bag_id])
    else
      message_bag = MessageBag.find_by(id: postback_payload[:message_bag_id])
    end
    return if message_bag&.message_group&.user_id != instagram_account.user_id

    ChatbotUsageGroup.create(chatbot_usage: chatbot_usage, message_bag: message_bag, message_group: message_bag.message_group)

    messages = message_bag&.messages&.order(:order_no)
    messages.each do |message|
      return if InstagramUser.find_by(id: instagram_user.id).pending_message.present?
      chatbot_manager.message = message
      chatbot_manager.message_type = "dm_bag"
      chatbot_manager.call_graph_api
    end

    if postback_payload[:is_support].present?
      PageMailer.request_support_email(instagram_account.user, instagram_user).deliver
      SupportingUser.create instagram_account: instagram_account, instagram_user: instagram_user
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
    message_bag_ids.uniq
  end

  def create_instagram_user(sender_psid, usage_type, instagram_account, message_button_id)
    instagram_user = InstagramUser.create_with(start_chatbot_in: usage_type.split("_received")[0], start_chatbot_at: Time.current)
                                  .find_or_create_by(instagram_id: sender_psid, instagram_account: instagram_account)
    profile_result = graph_client(instagram_account.page_access_token).get(
      sender_psid.to_s,
      fields: 'name,username,follower_count,is_user_follow_business,is_business_follow_user'
    )
    if profile_result[:success]
      instagram_user_query = profile_result[:data]
      instagram_user.update!(
        username: instagram_user_query["username"],
        full_name: instagram_user_query["name"],
        follower_count: instagram_user_query["follower_count"],
        is_verified_user: instagram_user_query["is_verified_user"],
        is_user_follow_business: instagram_user_query["is_user_follow_business"],
        is_business_follow_user: instagram_user_query["is_business_follow_user"]
      )
    end

    if message_button_id.present?
      message_button = MessageButton.find_by(id: message_button_id)
      # if message_button.is_purchase_button_yes?
      #   Conversion.create(instagram_user: instagram_user,
      #                     user_name: instagram_user.username,
      #                     user_source: instagram_user.start_chatbot_in,
      #                     conversion_at: Time.current,
      #                     message_bag_id: message_button.message_bag_id)
      # end
      message_button_labels = message_button&.message_button_labels
      if message_button_labels.present?
        create_instagram_user_label(message_button_labels, instagram_user)
      end
    end

    instagram_user
    # end
  end

  def create_chatbot_usage(instagram_user, usage_type, content, instagram_account, media_id)
    chatbot_usage = ChatbotUsage.new(instagram_user: instagram_user, usage_type: usage_type, content: content, instagram_account: instagram_account, media_id: media_id)
    if ChatbotUsage.where(media_id: media_id).where.not(media_start_at: nil).blank? && media_id.present?
      media_result = graph_client(instagram_account.page_access_token).get(media_id.to_s, fields: 'id,timestamp')
      chatbot_usage.media_start_at = media_result.dig(:data, "timestamp").to_datetime if media_result.dig(:data, "timestamp").present?
    end
    chatbot_usage.save!
    chatbot_usage
  end

  def extract_message_text(received_message)
    return received_message[:text] if received_message[:text].present?

    attachments = received_message[:attachments] || []
    attachments.each do |attachment|
      attachment_type = attachment[:type].to_s
      next unless ['ig_post', 'share'].include?(attachment_type)

      title = attachment.dig(:payload, :title)
      return title if title.present?

      url = attachment.dig(:payload, :url)
      return url if url.present?
    end

    nil
  end

  def graph_client(access_token)
    FacebookManager::GraphApiClient.new(access_token)
  end

  def check_user_message(instagram_user, received_message_text, chatbot_manager)
    return true if instagram_user.pending_message_id.blank?
    return false if received_message_text.blank?

    # ActiveRecord::Base.transaction do
    if instagram_user.pending_message&.free_input&.present?
      free_input = instagram_user.pending_message.free_input
      free_input_labels = instagram_user.pending_message.free_input.free_input_labels
      if free_input.format_check_email?
        if instagram_user.update(email: received_message_text, pending_message_id: nil)
          create_instagram_user_label(free_input_labels, instagram_user) if free_input_labels.present?
          return true
        end
      elsif free_input.format_check_phone_number?
        if instagram_user.update(phone_number: received_message_text, pending_message_id: nil)
          create_instagram_user_label(free_input_labels, instagram_user) if free_input_labels.present?
          return true
        end
      elsif free_input.format_check_real_name?
        if instagram_user.update(real_name: received_message_text, pending_message_id: nil)
          create_instagram_user_label(free_input_labels, instagram_user) if free_input_labels.present?
          return true
        end
      elsif free_input.format_check_company_name?
        if instagram_user.update(company_name: received_message_text, pending_message_id: nil)
          create_instagram_user_label(free_input_labels, instagram_user) if free_input_labels.present?
          return true
        end
      elsif free_input.format_check_company_role?
        if instagram_user.update(company_role: received_message_text, pending_message_id: nil)
          create_instagram_user_label(free_input_labels, instagram_user) if free_input_labels.present?
          return true
        end
      elsif free_input.format_check_website?
        if instagram_user.update(website: received_message_text, pending_message_id: nil)
          create_instagram_user_label(free_input_labels, instagram_user) if free_input_labels.present?
          return true
        end
      elsif free_input.format_check_propose?
        if instagram_user.update(propose: received_message_text, pending_message_id: nil)
          create_instagram_user_label(free_input_labels, instagram_user) if free_input_labels.present?
          return true
        end
      elsif free_input.format_check_know_product_in?
        if instagram_user.update(know_product_in: received_message_text, pending_message_id: nil)
          create_instagram_user_label(free_input_labels, instagram_user) if free_input_labels.present?
          return true
        end
      elsif free_input.format_check_no_validate?
        if instagram_user.update(pending_message_id: nil)
          create_instagram_user_label(free_input_labels, instagram_user) if free_input_labels.present?
          return true
        end
      end

      if free_input.format_check_email? || free_input.format_check_phone_number?
        chatbot_manager.payload = InstagramUser.find_by(id: instagram_user.id).pending_message&.free_input&.format_check_message
        chatbot_manager.call_postback_api
      end
      return false
    elsif instagram_user.pending_message_id.present? && Message.find_by(id: instagram_user.pending_message_id).blank?
      return instagram_user.update(pending_message_id: nil)
    end
    return false
  end

  def create_instagram_user_label(labels, instagram_user)
    labels.each do |label|
      InstagramUserLabel.find_or_create_by(name: label.label_name, instagram_user: instagram_user)
    end
  end
end
