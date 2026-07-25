class MessageGroupForm
  include ActiveModel::Model

  attr_reader :message_group
  attr_reader :current_user

  def initialize(message_group, current_user)
    @message_group = message_group
    @instagram_account = current_user.instagram_account
  end

  def check_delete
    list_bag_ids = @message_group.message_bags.pluck(:id)
    return true if list_bag_ids.blank?

    list_bag_ids.each do |bag_id|
      return false if globally_referenced?(bag_id)
    end

    return true if @instagram_account.blank?

    referenced_ids = account_referenced_bag_ids
    list_bag_ids.each do |bag_id|
      return false if referenced_ids.include?(bag_id)
    end

    true
  end

  private

  def globally_referenced?(bag_id)
    PersistentMenu.where(message_bag_id: bag_id).exists? ||
      IceBreaker.where(message_bag_id: bag_id).exists? ||
      MessageButton.where(message_bag_id: bag_id).exists? ||
      Conversion.where(message_bag_id: bag_id).exists?
  end

  def account_referenced_bag_ids
    ids = KeywordSetting.where(instagram_account_id: @instagram_account.id).pluck(:message_bag_id)
    ids << @instagram_account.post_comment_bag_id if @instagram_account.post_comment_bag_id.present?
    ids << @instagram_account.story_comment_bag_id if @instagram_account.story_comment_bag_id.present?
    ids << @instagram_account.live_comment_bag_id if @instagram_account.live_comment_bag_id.present?
    ids << @instagram_account.default_reply_bag_id if @instagram_account.default_reply_bag_id.present?
    ids.compact
  end
end
