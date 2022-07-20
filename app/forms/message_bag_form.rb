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
    list_bag_ids = [@instagram_account.post_comment_bag_id, @instagram_account.story_comment_bag_id, @instagram_account.live_comment_bag_id]
    if list_bag_ids.present?
      return false if list_bag_ids.include?(@message_bag.id)
    end
    return true
  end
end
