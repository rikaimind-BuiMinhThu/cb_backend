class Api::V1::MessageManagements::MessageGroupsController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  def index
    render json: {code: 1, data: MessageGroup.all}
  end

  def create
    message_group = MessageGroup.create(message_group_params)
    render json: {code: 1, data: message_group}
  end

  def show
    message_group = MessageGroup.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find message group"} if message_group.blank?
    message_bags = MessageBag.where(message_group: message_group)
    render json: {code: 1, data: {message_group: message_group, message_bags: message_bags}}
  end

  def update
    message_group = MessageGroup.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find message group"}  if message_group.blank?
    message_group.update message_group_params
    render json: {code: 1, data: message_group}
  end

  def destroy
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel?
    MessageGroup.destroy(id: params[:id])
  end

  private

  def message_group_params
    params.require(:message_group).permit(:group_name, :user_id)
  end
end
