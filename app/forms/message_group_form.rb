class MessageGroupForm
  include ActiveModel::Model

  GROUP_PREFIX = "グループ内のメッセージ袋が".freeze

  attr_reader :message_group
  attr_reader :current_user

  def initialize(message_group, current_user)
    @message_group = message_group
    @current_user = current_user
  end

  def check_delete
    delete_block_reason.nil?
  end

  def delete_block_reason
    list_bag_ids = @message_group.message_bags.pluck(:id)
    return nil if list_bag_ids.blank?

    list_bag_ids.each do |bag_id|
      reason = bag_block_reason(bag_id)
      return "#{GROUP_PREFIX}#{reason}" if reason.present?
    end

    nil
  end

  private

  def bag_block_reason(bag_id)
    bag = MessageBag.find_by(id: bag_id)
    return nil if bag.blank?

    MessageBagForm.new(bag, @current_user).delete_block_reason
  end
end
