# frozen_string_literal: true

owner = User.find_by!(email: "client-admin@local.test")

message_group = MessageGroup.find_or_initialize_by(user: owner, group_name: "Local Welcome Group")
message_group.save!

message_bag = MessageBag.find_or_initialize_by(message_group: message_group, bag_name: "Local Welcome Bag")
message_bag.save!

message = Message.find_or_initialize_by(message_bag: message_bag, order_no: 1)
message.assign_attributes(
  message_type: :msg,
  message_value: "こんにちは！ローカル検証用の自動返信です。"
)
message.save!

HotTemplate.find_or_create_by!(message_group: message_group, title: "Local Hot Template") do |template|
  template.description = "Seed hot template for Instagram replies"
end

default_bag = MessageBag.find_or_initialize_by(message_group: message_group, bag_name: "Local Default Reply")
default_bag.save!

Message.find_or_initialize_by(message_bag: default_bag, order_no: 1).tap do |default_message|
  default_message.message_type = :msg
  default_message.message_value = "キーワードに一致しませんでした。別の内容をお試しください。"
  default_message.save!
end
