namespace :message_demo do
  task run: :environment do
    puts 'create message demo ...'

    message_group = MessageGroup.create group_name: "Message Group", user_id: 1
    message_bag = MessageBag.create bag_name: "Message Bag", message_group: message_group
    Message.create message_bag: message_bag, message_value: "Hello. This is the EC Chatbot. How can I help you?"
    message = Message.create message_bag: message_bag, message_value: "Here the FAQ. How can I help you?"
    QuickReply.create message: message, title: "What is EC Chatbot?"
    QuickReply.create message: message, title: "Learn more"
    Message.create message_bag: message_bag, message_value: "EC Chatbot is super bot"
    Message.create message_bag: message_bag, message_value: "EC Chatbot is on progress. Please stay tune!"
    # IceBreaker.create question: "How can I help you", answer: "Please chat with EC Chatbot"
    # IceBreaker.create question: "Where are you from", answer: "I'm from facebook and instagram"
    # PersistentMenu.create title: "How can I help you", payload: "Please chat with EC Chatbot"
    # PersistentMenu.create title: "Where are you from", payload: "I'm from facebook and instagram"
    # PersistentMenu.create title: "Extend url", url: "https://example.com/"
    InstagramAccount.create(
      user_id: 1,
      ig_id: "17841453981073051",
      page_id: "102197405864941",
      fb_user_id: "103192899082863",
      page_access_token: "EAAYoYLoNogABAGcM1xaGmKS2Hm4SXFS2P29CPediPLneIcR8KtghvWwci82mdmVSQvSJOOgIM4wge8rdZBcKeBRGdoYuBtsoTttPsdwMcE5VGj3DYtVz1jghtPtS1wMZChi6tZAi9VsljarKM8bJWbVqesABkNdQRe26NMufOSsuDYCJPHLKU1x3G9kXZAMZD",
     )
  end
end
