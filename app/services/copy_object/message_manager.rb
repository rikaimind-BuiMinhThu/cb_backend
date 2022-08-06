module CopyObject
  class MessageManager
    attr_reader :message_origin
    attr_reader :type

    def initialize(message_origin, type)
      @message_origin = message_origin
      @type = type
    end

    def call
      if @type == "group"
        copy_group @message_origin
      elsif @type == "bag"
        copy_bag @message_origin, nil
      end
      return true
    end

    private

    def copy_group message_group
      if MessageGroup.find_by(group_name: message_group.group_name + " Copy",
                              user_id: message_group.user_id).present?
        index = 0
        loop do
          index += 1
          temp_message = MessageGroup.find_by(group_name: message_group.group_name + " Copy #{index}",
                                              user_id: message_group.user_id)
          break if temp_message.blank?
        end
        new_message_group = MessageGroup.create(group_name: message_group.group_name + " Copy #{index}",
                                                user_id: message_group.user_id)
      else
        new_message_group = MessageGroup.create(group_name: message_group.group_name + " Copy",
                                                user_id: message_group.user_id)
      end
      message_group.message_bags.each do |message_bag|
        copy_bag message_bag, new_message_group.id
      end
    end

    def copy_bag message_bag, message_group_id
      if message_group_id.present?
        new_message_bag = MessageBag.create(bag_name: message_bag.bag_name,
                                            message_group_id: message_group_id)
      else
        new_message_bag = MessageBag.create(bag_name: message_bag.bag_name + " Copy",
                                            message_group_id: message_bag.message_group_id)
      end
      list_messages = message_bag.messages.select(:message_value, :message_type, :img_value, :preview_past_post_url)
      data_messages = []
      list_messages.each do |message|
        data_messages.push({
          "message_value": message.message_value,
          "message_type": message.message_type,
          "img_value": !message.img_value ? message.img_value.to_s : nil,
          "preview_past_post_url": message.preview_past_post_url,
          "message_bag_id": new_message_bag.id
        })
      end
      Message.insert_all(data_messages) if data_messages.present?
    end
  end
end
