json.code 1
json.data @instagram_accounts.each do |instagram_account|
  json.merge! instagram_account.as_json
  json.post_comment_group_name MessageBag.find_by(id: instagram_account.post_comment_bag_id)&.message_group&.group_name if instagram_account.post_comment_bag_id.present?
  json.story_comment_group_name MessageBag.find_by(id: instagram_account.story_comment_bag_id)&.message_group&.group_name if instagram_account.story_comment_bag_id.present?
  json.live_comment_group_name MessageBag.find_by(id: instagram_account.live_comment_bag_id)&.message_group&.group_name if instagram_account.live_comment_bag_id.present?
end
