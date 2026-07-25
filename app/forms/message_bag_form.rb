class MessageBagForm
  include ActiveModel::Model

  REASON_PERSISTENT_MENU = "固定メニューで使用中のため、削除できません。".freeze
  REASON_ICE_BREAKER = "FAQ（アイスブレーカー）で使用中のため、削除できません。".freeze
  REASON_MESSAGE_BUTTON = "他のメッセージのボタン先として使用中のため、削除できません。".freeze
  REASON_CONVERSION = "コンバージョンで使用中のため、削除できません。".freeze
  REASON_KEYWORD = "キーワード設定で使用中のため、削除できません。".freeze
  REASON_POST_COMMENT = "投稿コメントの返信設定で使用中のため、削除できません。".freeze
  REASON_STORY_COMMENT = "ストーリー返信設定で使用中のため、削除できません。".freeze
  REASON_LIVE_COMMENT = "ライブコメントの返信設定で使用中のため、削除できません。".freeze
  REASON_DEFAULT_REPLY = "デフォルト返信に設定中のため、削除できません。".freeze

  attr_reader :message_bag
  attr_reader :current_user

  def initialize(message_bag, current_user)
    @message_bag = message_bag
    @instagram_account = current_user.instagram_account
  end

  def check_delete
    delete_block_reason.nil?
  end

  def delete_block_reason
    bag_id = @message_bag.id
    reason = global_block_reason(bag_id)
    return reason if reason.present?
    return nil if @instagram_account.blank?

    account_block_reason(bag_id)
  end

  private

  def global_block_reason(bag_id)
    return REASON_PERSISTENT_MENU if PersistentMenu.where(message_bag_id: bag_id).exists?
    return REASON_ICE_BREAKER if IceBreaker.where(message_bag_id: bag_id).exists?
    return REASON_MESSAGE_BUTTON if MessageButton.where(message_bag_id: bag_id).exists?
    return REASON_CONVERSION if Conversion.where(message_bag_id: bag_id).exists?

    nil
  end

  def account_block_reason(bag_id)
    if KeywordSetting.where(instagram_account_id: @instagram_account.id, message_bag_id: bag_id).exists?
      return REASON_KEYWORD
    end
    return REASON_POST_COMMENT if @instagram_account.post_comment_bag_id == bag_id
    return REASON_STORY_COMMENT if @instagram_account.story_comment_bag_id == bag_id
    return REASON_LIVE_COMMENT if @instagram_account.live_comment_bag_id == bag_id
    return REASON_DEFAULT_REPLY if @instagram_account.default_reply_bag_id == bag_id

    nil
  end
end
