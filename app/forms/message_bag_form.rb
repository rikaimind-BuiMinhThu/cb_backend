class MessageBagForm
  include ActiveModel::Model

  attr_reader :message_bag
  attr_reader :current_user

  def initialize(message_bag, current_user)
    @message_bag = message_bag
    @instagram_account = current_user.instagram_account
  end

  def check_delete
    return false if @instagram_account.blank?
    return false if PersistentMenu.where(message_bag_id: @message_bag.id).exist?
    return false if IceBreaker.where(message_bag_id: @message_bag.id).exist?
    return false if MessageButton.where(message_bag_id: @message_bag.id).exist?
    list_setting_ids = KeywordSetting.where(instagram_account_id: @instagram_account.id).pluck(:message_bag_id)
    list_setting_ids.push(@instagram_account.post_comment_bag_id) if @instagram_account.post_comment_bag_id.present?
    list_setting_ids.push(@instagram_account.story_comment_bag_id) if @instagram_account.story_comment_bag_id.present?
    list_setting_ids.push(@instagram_account.live_comment_bag_id) if @instagram_account.live_comment_bag_id.present?
    if list_setting_ids.present?
      return false if list_setting_ids.include?(@message_bag.id)
    end
    return true
  end
end
