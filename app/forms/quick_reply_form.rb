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
            message_tmp = Message.create(message_bag_id: message[:message_bag_id],
                                         received_message: message[:received_message],
                                         message_value: message[:message_value],
                                         message_type: message[:message_type])
            list_quick_replies = []
            message[:title].each do |msg|
              list_quick_replies.push({message_id: message_tmp.id, title: msg[:received_message]})
            end
            QuickReply.insert_all!(list_quick_replies)
            list_messages += message[:title]
          end
          Message.insert_all!(list_messages)
        end
      end
    rescue Exception => e
      errors.add(:base, e)
    end
  end
end
