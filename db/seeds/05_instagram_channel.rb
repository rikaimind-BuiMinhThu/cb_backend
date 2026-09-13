# frozen_string_literal: true

owner = User.find_by!(email: "client-admin@local.test")
message_group = MessageGroup.find_by!(user: owner, group_name: "Local Welcome Group")
welcome_bag = MessageBag.find_by!(message_group: message_group, bag_name: "Local Welcome Bag")
default_bag = MessageBag.find_by!(message_group: message_group, bag_name: "Local Default Reply")

instagram_account = InstagramAccount.find_or_initialize_by(ig_id: "seed_ig_local_dev_001")
instagram_account.user = owner
instagram_account.page_id = "seed_page_local_001"
instagram_account.fb_user_id = "seed_fb_user_001"
instagram_account.page_access_token = "seed-local-token-not-for-production"
instagram_account.default_reply_bag = default_bag
instagram_account.post_comment_bag = welcome_bag
instagram_account.story_comment_bag = welcome_bag
instagram_account.live_comment_bag = welcome_bag
instagram_account.save!

KeywordSetting.find_or_create_by!(instagram_account: instagram_account, keyword: "hello") do |setting|
  setting.title = "Hello keyword"
  setting.message_bag = welcome_bag
  setting.is_dm = true
  setting.is_post_comment = true
  setting.is_story_comment = false
  setting.is_live_comment = false
  setting.is_active = true
end

KeywordSetting.find_or_create_by!(instagram_account: instagram_account, keyword: "購入") do |setting|
  setting.title = "Purchase keyword"
  setting.message_bag = welcome_bag
  setting.is_dm = true
  setting.is_post_comment = true
  setting.is_story_comment = true
  setting.is_live_comment = false
  setting.is_active = true
end

IceBreaker.find_or_create_by!(instagram_account: instagram_account, question: "商品について知りたい") do |breaker|
  breaker.message_bag_id = welcome_bag.id
end

PersistentMenu.find_or_create_by!(instagram_account: instagram_account, title: "公式サイト") do |menu|
  menu.url = "https://example.com"
  menu.message_bag_id = welcome_bag.id
  menu.is_support = false
end

15.times do |index|
  day_offset = index
  ig_user = InstagramUser.find_or_initialize_by(
    instagram_account: instagram_account,
    instagram_id: "seed_ig_user_#{format('%03d', index + 1)}"
  )
  ig_user.assign_attributes(
    username: "seed_user_#{index + 1}",
    full_name: "Seed User #{index + 1}",
    real_name: "Seed Real #{index + 1}",
    email: "seed.user#{index + 1}@example.com",
    phone_number: "0901234567#{index % 10}",
    follower_count: 100 + (index * 17),
    status: [:lead, :progression, :completion, :archive][index % 4],
    start_chatbot_in: :dm,
    is_verified_user: false,
    is_user_follow_business: true,
    is_business_follow_user: false
  )
  ig_user.save!
  ig_user.update_columns(created_at: day_offset.days.ago, updated_at: day_offset.days.ago)

  usage = ChatbotUsage.find_or_initialize_by(
    instagram_account: instagram_account,
    instagram_user: ig_user,
    content: "seed-dm-#{index + 1}"
  )
  usage.usage_type = :dm_received
  usage.save!
  usage.update_columns(created_at: day_offset.days.ago, updated_at: day_offset.days.ago)

  ChatbotUsageGroup.find_or_create_by!(chatbot_usage: usage, message_group: message_group) do |group|
    group.message_bag = welcome_bag
  end
end
