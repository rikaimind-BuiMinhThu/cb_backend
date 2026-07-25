module CopyObject
  class MessageManager
    attr_reader :message_origin, :type, :current_user_id

    def initialize(message_origin, type, current_user_id)
      @message_origin = message_origin
      @type = type
      @current_user_id = current_user_id
    end

    def call
      if @type == "group"
        copy_group @message_origin, @current_user_id
      elsif @type == "bag"
        copy_bag @message_origin, nil, {}
      end
      return true
    end

    private

    def copy_group message_group, current_user
      if MessageGroup.find_by(group_name: message_group.group_name + " Copy",
                              user_id: current_user_id).present?
        index = 0
        loop do
          index += 1
          temp_message = MessageGroup.find_by(group_name: message_group.group_name + " Copy #{index}",
                                              user_id: current_user_id)
          break if temp_message.blank?
        end
        new_message_group = MessageGroup.create!(group_name: message_group.group_name + " Copy #{index}",
                                                user_id: current_user_id)
      else
        new_message_group = MessageGroup.create!(group_name: message_group.group_name + " Copy",
                                                user_id: current_user_id)
      end

      bag_id_map = {}
      message_group.message_bags.each do |message_bag|
        new_message_bag = MessageBag.create!(
          bag_name: message_bag.bag_name,
          message_group_id: new_message_group.id
        )
        bag_id_map[message_bag.id] = new_message_bag.id
      end

      message_group.message_bags.each do |message_bag|
        copy_bag_messages(message_bag, bag_id_map[message_bag.id], bag_id_map)
      end
    end

    def copy_bag message_bag, message_group_id, bag_id_map = {}
      if message_group_id.present?
        new_message_bag = MessageBag.create!(bag_name: message_bag.bag_name,
                                            message_group_id: message_group_id)
      else
        new_message_bag = MessageBag.create!(bag_name: message_bag.bag_name + " Copy",
                                            message_group_id: message_bag.message_group_id)
      end
      copy_bag_messages(message_bag, new_message_bag.id, bag_id_map)
    end

    def copy_bag_messages(message_bag, new_message_bag_id, bag_id_map)
      message_bag.messages.order(:order_no).each do |message|
        new_message = Message.new(
          message_value: message.message_value,
          message_type: message.message_type,
          preview_past_post_url: message.preview_past_post_url,
          message_bag_id: new_message_bag_id,
          order_no: message.order_no
        )
        if message.img_value.present? && message.img_value.path.present? && File.exist?(message.img_value.path)
          File.open(message.img_value.path) do |file|
            new_message.img_value = file
            new_message.save!
          end
        else
          new_message.save!
        end

        message.message_buttons.each do |message_button|
          target_bag_id = message_button.message_bag_id
          if target_bag_id.present? && bag_id_map.key?(target_bag_id)
            target_bag_id = bag_id_map[target_bag_id]
          end

          new_button = MessageButton.create!(
            message: new_message,
            button_type: message_button.button_type,
            title: message_button.title,
            content: message_button.content,
            message_bag_id: target_bag_id,
            is_purchase_button: message_button.is_purchase_button
          )

          message_button.message_button_labels.each do |label|
            MessageButtonLabel.create!(
              message_button: new_button,
              label_name: label.label_name
            )
          end
        end

        if message.free_input.present?
          free_input = message.free_input
          new_free_input = FreeInput.create!(
            message: new_message,
            format_check: free_input.format_check,
            format_check_message: free_input.format_check_message
          )
          free_input.free_input_labels.each do |label|
            FreeInputLabel.create!(
              free_input: new_free_input,
              label_name: label.label_name
            )
          end
        end
      end
    end
  end
end
