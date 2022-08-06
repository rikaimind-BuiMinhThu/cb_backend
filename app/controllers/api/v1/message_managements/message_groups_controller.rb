class Api::V1::MessageManagements::MessageGroupsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    message_groups = MessageGroup.where(user_id: current_user.id)
    render json: {code: 1, data: message_groups}
  end

  def create
    if MessageGroup.find_by(group_name: message_group_params[:group_name], user_id: current_user.id)
      render json: {code: 2, message: "Message group name has unique."}
      return
    end
    message_group = MessageGroup.create(group_name: message_group_params[:group_name], user_id: current_user.id)
    render json: {code: 1, data: message_group}
  end

  def show
    message_group = MessageGroup.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message group"} if message_group.blank?
    return render json: {code: 2, message: "User can't permission"} if message_group.user_id != current_user.id
    message_bags = MessageBag.where(message_group: message_group)
    render json: {code: 1, data: {message_group: message_group, message_bags: message_bags}}
  end

  def update
    message_group = MessageGroup.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message group"}  if message_group.blank?
    return render json: {code: 2, message: "User can't permission"} if message_group.user_id != current_user.id
    message_group.update message_group_params
    render json: {code: 1, data: message_group}
  end

  def destroy
    message_group = MessageGroup.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message group"}  if message_group.blank?
    return render json: {code: 2, message: "User can't permission"} if message_group.user_id != current_user.id
    return render json: {code: 2, message: "Cannot delete message group"} unless MessageGroupForm.new(message_group, current_user).check_delete
    if message_group.destroy
      render json: {code: 1, message: "Success!"}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  def copy
    message_group = MessageGroup.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message group"}  if message_group.blank?
    return render json: {code: 2, message: "User can't permission"} if message_group.user_id != current_user.id
    if CopyObject::MessageManager.new(message_group, "group").call
      render json: {code: 1, message: "Success!"}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  private

  def message_group_params
    params.require(:message_group).permit(:group_name)
  end
end
