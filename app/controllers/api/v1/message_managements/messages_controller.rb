class Api::V1::MessageManagements::MessagesController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  def create
    quick_reply_create = QuickReplyForm.new(params[:messages]).call
    return render json: {code: 2, message: quick_reply_create.to_s} if quick_reply_create != 1
    render json: {code: 1, message: "success"}
  end

  def show
    message = Message.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find message bag"} if message.blank?
    render json: {code: 1, data: messages}
  end

  def update
    message = Message.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find message bag"} if message.blank?
    message.update message_params
    render json: {code: 1, data: message}
  end

  def destroy
    message = Message.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find message bag"} if message.blank?
    message.destroy
    render json: {code: 1, data: message}
  end

  private

  def message_params
    params.require(:message).permit(:message_bag_id, :received_message, :message_value, :message_type)
  end
end
