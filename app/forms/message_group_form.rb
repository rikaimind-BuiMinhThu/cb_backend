class MessageGroupForm
  include ActiveModel::Model

  attr_reader :message_group
  attr_reader :current_user

  def initialize(message_group, current_user)
    @message_group = message_group
    @instagram_account = current_user.instagram_account
  end

  def check_delete
    return false if @instagram_account.blank?
    list_bag_ids = @message_group.message_bags.pluck(:id)
    if list_bag_ids.present?
      if @instagram_account.post_comment_bag_id.present?
        return false if list_bag_ids.include?(@instagram_account.post_comment_bag_id)
      elsif  @instagram_account.story_comment_bag_id.present?
        return false if list_bag_ids.include?(@instagram_account.story_comment_bag_id)
      elsif @instagram_account.live_comment_bag_id.present?
        return false if list_bag_ids.include?(@instagram_account.live_comment_bag_id)
      end
    end
    return true
  end
end
