class MessageGroupForm
  include ActiveModel::Model

  attr_reader :message_group
  attr_reader :current_user

  def initialize(message_group, current_user)
    @message_group = message_group
    @instagram_account = current_user.instagram_account
  end

  def check_delete
    return true if @instagram_account.blank?
    list_setting_ids = KeywordSetting.where(instagram_account_id: @instagram_account.id).pluck(:message_bag_id)
    list_setting_ids.push(@instagram_account.post_comment_bag_id) if @instagram_account.post_comment_bag_id.present?
    list_setting_ids.push(@instagram_account.story_comment_bag_id) if @instagram_account.story_comment_bag_id.present?
    list_setting_ids.push(@instagram_account.live_comment_bag_id) if @instagram_account.live_comment_bag_id.present?
    list_bag_ids = @message_group.message_bags.pluck(:id)
    if list_bag_ids.present?
      list_bag_ids.each do |bag_id|
        return false if list_setting_ids.include?(bag_id)
      end
    end
    return true
  end
end
