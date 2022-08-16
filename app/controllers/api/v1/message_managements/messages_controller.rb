class Api::V1::MessageManagements::MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    ActiveRecord::Base.transaction do
      message = Message.new(message_params)
      message_bag = MessageBag.find_by(id: message_params[:message_bag_id])
      message.order_no = message_bag&.messages&.order(:order_no).last&.order_no.to_i + 1
      if message.save

        if params[:message][:message_buttons].present?
          params[:message][:message_buttons].each do |message_button_data|
            message_button = MessageButton.create(message: message, button_type: message_button_data[:button_type], title: message_button_data[:title], content: message_button_data[:content], message_bag_id: message_button_data[:message_bag_id], is_purchase_button: message_button_data[:is_purchase_button])
            if message_button_data[:message_button_labels].present?
              message_button_data[:message_button_labels].each do |message_button_label|
                MessageButtonLabel.create(message_button: message_button, label_name: message_button_label[:label_name])
              end
            end
          end
        end

        if params[:message][:message_buttons].blank? && params[:message][:free_input].present?
          free_input_params = params[:message][:free_input]
          free_input = FreeInput.create(message: message, format_check: free_input_params[:format_check], format_check_message: free_input_params[:format_check_message])
          if free_input_params[:free_input_labels].present?
            free_input_params[:free_input_labels].each do |free_input_label|
              FreeInputLabel.create(free_input: free_input, label_name: free_input_label[:label_name])
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
      message_buttons = MessageButton.where(message: message)
      message_buttons.each do |message_button|
        MessageButtonLabel.where(message_button_id: message_button.id).delete_all
      end
      message_buttons.delete_all

      free_inputs = FreeInput.where(message: message)
      free_inputs.each do |free_input|
        FreeInputLabel.where(free_input_id: free_input.id).delete_all
      end
      free_inputs.delete_all
      message.update(message_params)

      if params[:message][:message_buttons].present?
        params[:message][:message_buttons].each do |message_button_data|
          message_button = MessageButton.create(message: message, button_type: message_button_data[:button_type], title: message_button_data[:title], content: message_button_data[:content], message_bag_id: message_button_data[:message_bag_id], is_purchase_button: message_button_data[:is_purchase_button])
          if message_button_data[:message_button_labels].present?
            message_button_data[:message_button_labels].each do |message_button_label|
              MessageButtonLabel.create(message_button: message_button, label_name: message_button_label[:label_name])
            end
          end
        end
      end

      if params[:message][:message_buttons].blank? && params[:message][:free_input].present?
        free_input_params = params[:message][:free_input]
        free_input = FreeInput.create(message: message, format_check: free_input_params[:format_check], format_check_message: free_input_params[:format_check_message])
        if free_input_params[:free_input_labels].present?
          free_input_params[:free_input_labels].each do |free_input_label|
            FreeInputLabel.create(free_input: free_input, label_name: free_input_label[:label_name])
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
        MessageButtonLabel.where(message_button_id: message_button.id).delete_all
      end
      message_buttons.delete_all

      free_inputs = FreeInput.where(message: message)
      free_inputs.each do |free_input|
        FreeInputLabel.where(free_input_id: free_input.id).delete_all
      end
      free_inputs.delete_all
      message.destroy
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, message: "Success!"}
  end

  def move
    message = Message.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message bag"} if message.blank?
    return render json: {code: 2, message: "Message not change"} if params[:messages].index(message.id).to_i + 1 == message.order_no
    return render json: {code: 2, message: "Error!"} if params[:messages].blank?
    params[:messages].each_with_index do |id, index|
      Message.find_by(id: id)&.update order_no: index + 1
    end
    render json: {code: 1, message: "Success!"}
  end

  private

  def message_params
    params.require(:message).permit(:message_bag_id, :message_value, :message_type,
      :img_value, :preview_past_post_url)
  end
end
