class Api::V1::MessageManagements::MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    # quick_reply_create = QuickReplyForm.new(params[:messages]).call
    # return render json: {code: 2, message: quick_reply_create.to_s} if quick_reply_create != 1

    ActiveRecord::Base.transaction do
      message = Message.create(message_params)
      if params[:message][:message_buttons].present?
        params[:message][:message_buttons].each do |message_button_data|
          message_button = MessageButton.create(message: message, button_type: message_button_data[:button_type], title: message_button_data[:title], content: message_button_data[:content], message_bag_id: message_button_data[:message_bag_id])
          if message_button_data[:message_button_labels].present?
            message_button_data[:message_button_labels].each do |message_button_label|
              MessageButtonLabel.create(message_button: message_button, label_name: message_button_label[:label_name])
            end
          end
        end
      end
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, message: "Success"}
  end

  def show
    message = Message.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message bag"} if message.blank?
    message_buttons = MessageButton.where(message: message)
    render json: {code: 1, data: message, message_buttons: message_buttons}
  end

  def update
    message = Message.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message bag"} if message.blank?
    ActiveRecord::Base.transaction do
      message = Message.update(message_params)
      message_buttons = MessageButton.where(message: message)
      message_buttons.each do |message_button|
        message_buttons.message_button_labels.delete_all
      end
      message_buttons.delete_all
      if params[:message][:message_buttons].present?
        params[:message][:message_buttons].each do |message_button_data|
          message_button = MessageButton.create(message: message, button_type: message_button_data[:button_type], title: message_button_data[:title], content: message_button_data[:content], message_bag_id: message_button_data[:message_bag_id])
          if message_button_data[:message_button_labels].present?
            message_button_data[:message_button_labels].each do |message_button_label|
              MessageButtonLabel.create(message_button: message_button, label_name: message_button_label[:label_name])
            end
          end
        end
      end
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    message.update message_params
    render json: {code: 1, data: message}
  end

  def destroy
    message = Message.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message bag"} if message.blank?
    ActiveRecord::Base.transaction do
      message_buttons = MessageButton.where(message: message)
      message_buttons.each do |message_button|
        message_buttons.message_button_labels.delete_all
      end
      message_buttons.delete_all
      message.destroy
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, message: "Success!"}
  end

  private

  def message_params
    params.require(:message).permit(:message_bag_id, :message_value, :message_type,
      :img_value, :preview_past_post_url)
  end
end
