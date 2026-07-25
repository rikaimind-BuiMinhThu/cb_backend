class MessageBagForm
  include ActiveModel::Model

  attr_reader :message_bag
  attr_reader :current_user

  def initialize(message_bag, current_user)
    @message_bag = message_bag
    @instagram_account = current_user.instagram_account
  end

  def check_delete
    bag_id = @message_bag.id
    return false if globally_referenced?(bag_id)
    return true if @instagram_account.blank?
    return false if account_referenced_bag_ids.include?(bag_id)

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
