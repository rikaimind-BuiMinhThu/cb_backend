class QuickReplyForm
  include ActiveModel::Model

  attr_reader :messages

  def initialize(messages = [])
    @messages = messages
  end

  def call
    begin
      Message.transaction do
        QuickReply.transaction do
          list_messages = []
          @messages.each do |message|
            message_tmp = Message.create!(message_bag_id: message[:message_bag_id],
                                         message_value: message[:message_value],
                                         message_type: message[:message_type],
                                         img_value: message[:img_value])
            # next if message[:title].blank?
            # message[:title].each do |msg|
            #   QuickReply.create!(message_id: message_tmp.id, title: msg[:received_message])
            #   Message.create!(message_bag_id: msg[:message_bag_id],
            #                  received_message: msg[:received_message],
            #                  message_value: msg[:message_value],
            #                  message_type: msg[:message_type])
            end
          end
        end
      end
      return 1
    rescue Exception => e
      Rails.logger.debug(e)
      return e
    end
  end
end
