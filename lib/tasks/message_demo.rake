namespace :message_demo do
  task run: :environment do
    puts 'create message demo ...'

    message_group = MessageGroup.create group_name: "Message Group"
    message_bag = MessageBag.create bag_name: "Message Group", message_group: message_group
    Message.create message_bag: message_bag, received_message: "Hello", message_value: "Hello. This is the EC Chatbot. How can I help you?"
    message = Message.create message_bag: message_bag, received_message: "faq", message_value: "Here the FAQ. How can I help you?"
    QuickReply.create message: message, title: "What is EC Chatbot?"
    QuickReply.create message: message, title: "Learn more"
    Message.create message_bag: message_bag, received_message: "What is EC Chatbot?", message_value: "EC Chatbot is super bot"
    Message.create message_bag: message_bag, received_message: "Learn more", message_value: "EC Chatbot is on progress. Please stay tune!"
  end
end
