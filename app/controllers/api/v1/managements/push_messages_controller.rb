class Api::V1::Managements::PushMessagesController < ApplicationController
  def index
    chatbot = find_chatbot
    return if chatbot.blank?
    push_messages = chatbot.push_messages
    return render json: {code: 1, data: push_messages}
  end

  def create
    chatbot = find_chatbot
    return if chatbot.blank?
    ActiveRecord::Base.transaction do
      push_message = PushMessage.new(push_message_params)
      push_message.chatbot = chatbot
      push_message.save!
      if params[:push_message].present? && params[:push_message][:variables].present?
        params[:push_message][:variables].each do |variable|
          push_message_variable = PushMessageVariable.new(push_message_variable_params(variable))
          push_message_variable.push_message = push_message
          push_message_variable.save!
        end
      end
      render json: {code: 1, message: push_message}
    rescue StandardError => error
      Rails.logger.error(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      return render json: {code: 2, message: error}
    end
  end

  def show
    @push_message = find_push_message
    return if @push_message.blank?
  end

  def update
    push_message = find_push_message(true)
    return if push_message.blank?
    ActiveRecord::Base.transaction do
      push_message.push_message_variables.each do |push_message_variable|
        push_message_variable.destroy!
      end
      push_message.update!(push_message_params)
      if params[:push_message].present? && params[:push_message][:variables].present?
        params[:push_message][:variables].each do |variable|
          push_message_variable = PushMessageVariable.new(push_message_variable_params(variable))
          push_message_variable.push_message = push_message
          push_message_variable.save!
        end
      end
      render json: {code: 1, message: push_message}
    rescue StandardError => error
      Rails.logger.error(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      render json: {code: 2, message: error}
    end
  end

  def destroy
    push_message = find_push_message(true)
    return if push_message.blank?
    return render json: {code: 2, data: "Cannot find push message"} if push_message.blank?
    return render json: {code: 2, data: "No permission"} if current_user.admin_client? && push_message.chatbot.user_chatbots.where(roles: [:bot_admin, :editor]).pluck(:user_id).include?(current_user.id)
    ActiveRecord::Base.transaction do
      push_message.push_message_variables.each do |push_message_variable|
        push_message_variable.destroy!
      end
      push_message.destroy!
      render json: {code: 1, message: push_message}
    rescue StandardError => error
      Rails.logger.error(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      render json: {code: 2, message: error}
    end
  end

  def subscribe
    push_message = find_push_message(true)
    return if push_message.blank?
    ActiveRecord::Base.transaction do
      push_message.update!(subscribe_status: :subscribe)
      render json: {code: 1, message: push_message.subscribe_status}
    rescue StandardError => error
      Rails.logger.error(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      render json: {code: 2, message: error}
    end
  end

  def unsubscribe
    push_message = find_push_message(true)
    return if push_message.blank?
    ActiveRecord::Base.transaction do
      push_message.update!(subscribe_status: :unsubscribe)
      render json: {code: 1, message: push_message.subscribe_status}
    rescue StandardError => error
      Rails.logger.error(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      render json: {code: 2, message: error}
    end
  end

  private

  def push_message_params
    params.require(:push_message).permit(:title, :sending_method, :email_id, :started_at,
      :has_timezone_exclusion, :excluded_time_from, :excluded_time_to, :alternate_send_time,
      :subscribe_status, :last_message_datetime_since)
  end

  def push_message_variable_params(variable)
    variable.permit(:variable_id, :operator, :value)
  end

  def find_chatbot
    render json: {code: 2, message: "Not have permission"} and return unless current_user.admin_deel? || current_user.admin_client?
    chatbot = Chatbot.find_by(id: params[:chatbot_id] || params[:id])
    render json: {code: 2, message: "Not found chatbot"} and return if chatbot.blank?
    user_chatbot = chatbot.user_chatbots.find_by(chatbot_id: params[:chatbot_id], user: current_user)
    render json: {code: 2, message: "Not have permission"} and return if current_user.admin_client? && user_chatbot.blank?
    chatbot
  end

  def find_push_message(editor_permission = false)
    render json: {code: 2, message: "Not have permission"} and return unless current_user.admin_deel? || current_user.admin_client?
    push_message = PushMessage.find_by(id: params[:id])
    render json: {code: 2, message: "Not found push message"} and return if push_message.blank?
    chatbot = push_message.chatbot
    render json: {code: 2, message: "Not found chatbot"} and return if chatbot.blank?
    user_chatbots = chatbot.user_chatbots.where(chatbot_id: params[:chatbot_id], user: current_user)
    user_chatbots = user_chatbots.where(role: [:bot_admin, :editor]) if editor_permission.present?
    render json: {code: 2, message: "Not have permission"} and return if current_user.admin_client? && user_chatbot.blank?
    push_message
  end
end
