json.code 1
json.data @instagram_accounts.each do |instagram_account|
  json.merge! instagram_account.as_json
  if instagram_account.post_comment_bag.present?
    post_comment_group = instagram_account.post_comment_bag.message_group
    json.post_comment_group_id post_comment_group&.id
    json.post_comment_group_name post_comment_group&.group_name
  end
  if instagram_account.story_comment_bag.present?
    story_comment_group = instagram_account.story_comment_bag.message_group
    json.story_comment_group_id story_comment_group&.id
    json.story_comment_group_name story_comment_group&.group_name
  end
  if instagram_account.live_comment_bag.present?
    live_comment_group = instagram_account.live_comment_bag.message_group
    json.live_comment_group_id live_comment_group&.id
    json.live_comment_group_name live_comment_group&.group_name
  end
  if instagram_account.default_reply_bag.present?
    default_reply_group = instagram_account.default_reply_bag.message_group
    json.default_reply_group_id default_reply_group&.id
    json.default_reply_group_name default_reply_group&.group_name
  end
end
