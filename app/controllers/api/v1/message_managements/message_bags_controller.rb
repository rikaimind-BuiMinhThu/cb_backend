class Api::V1::MessageManagements::MessageBagsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    message_bag = MessageBag.create(message_bag_params)
    render json: {code: 1, data: message_bag}
  end

  def show
    @message_bag = MessageBag.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message bag"} if @message_bag.blank?
    return render json: {code: 2, message: "User can't permission"} if @message_bag.message_group.user_id != current_user.id
    @messages = Message.where(message_bag: @message_bag).order(:order_no)
    # render json: {code: 1, data: {message_bag: message_bag, messages: messages}}
  end

  def update
    message_bag = MessageBag.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message bag"} if message_bag.blank?
    return render json: {code: 2, message: "User can't permission"} if message_bag.message_group.user_id != current_user.id
    message_bag.update message_bag_params
    render json: {code: 1, data: message_bag}
  end

  def destroy
    message_bag = MessageBag.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message bag"} if message_bag.blank?
    return render json: {code: 2, message: "User can't permission"} if message_bag.message_group.user_id != current_user.id
    return render json: {code: 2, message: "Cannot delete message bag"} unless MessageBagForm.new(message_bag, current_user).check_delete
    if message_bag.destroy
      render json: {code: 1, message: "Success!"}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  def copy
    message_bag = MessageBag.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message bag"} if message_bag.blank?
    return render json: {code: 2, message: "User can't permission"} if message_bag.message_group.user_id != current_user.id
    if CopyObject::MessageManager.new(message_bag, "bag").call
      render json: {code: 1, message: "Success!"}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  def move
    message_bag = MessageBag.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message bag"} if message_bag.blank?
    return render json: {code: 2, message: "User can't permission"} if message_bag.message_group.user_id != current_user.id
    new_message_group = MessageGroup.find_by(id: params[:message_group_id])
    return render json: {code: 2, message: "Cannot find message group"} if new_message_group.blank?
    return render json: {code: 2, message: "User can't permission"} if new_message_group.user_id != current_user.id
    message_bag.update message_group_id: params[:message_group_id]
    render json: {code: 1, data: message_bag}
  end

  private

  def message_bag_params
    params.require(:message_bag).permit(:message_group_id, :bag_name)
  end
end
