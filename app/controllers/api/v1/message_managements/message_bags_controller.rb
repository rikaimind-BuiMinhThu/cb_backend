class Api::V1::MessageManagements::MessageBagsController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  def create
    message_bag = MessageBag.create(message_bag_params)
    render json: {code: 1, data: message_bag}
  end

  def show
    message_bag = MessageBag.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find message bag"} if message_bag.blank?
    messages = Message.where(message_bag: message_bag)
    render json: {code: 1, data: {message_bag: message_bag, messages: messages}}
  end

  def update
    message_bag = MessageBag.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find message bag"} if message_bag.blank?
    message_bag.update message_bag_params
    render json: {code: 1, data: message_bag}
  end

  def destroy
    message_bag = MessageBag.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find message bag"} if message_bag.blank?
    message_bag.destroy
    render json: {code: 1, data: message_bag}
  end

  private

  def message_bag_params
    params.require(:message_bag).permit(:message_group_id, :bag_name)
  end
end
