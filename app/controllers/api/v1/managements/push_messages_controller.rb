class Api::V1::Managements::PushMessagesController < ApplicationController
  def index
    chatbot = find_chatbot
    return if chatbot.blank?

    @push_messages = chatbot.push_messages.includes(:push_message_variables)
    @total = @push_messages.length
    @push_messages = @push_messages.page(params[:page]) if params[:page] != 'all'
    render json: { code: 1, data: @push_messages, total: @total }
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
      run_schedule_job(push_message)
      render json: { code: 1, message: push_message }
    rescue StandardError => e
      Rails.logger.error(e)
      e.backtrace.each do |line|
        Rails.logger.error(line)
      end
      return render json: { code: 2, message: e }
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
      run_schedule_job(push_message)
      render json: { code: 1, message: push_message }
    rescue StandardError => e
      Rails.logger.error(e)
      e.backtrace.each do |line|
        Rails.logger.error(line)
      end
      render json: { code: 2, message: e }
    end
  end

  def destroy
    push_message = find_push_message(true)
    return if push_message.blank?
    return render json: { code: 2, message: 'Cannot find push message' } if push_message.blank?

    if current_user.admin_client? && push_message.chatbot.user_chatbots.where(role: %i[
                                                                                bot_admin editor
                                                                              ]).pluck(:user_id).exclude?(current_user.id)
      return render json: { code: 2,
                            message: 'No permission' }
    end

    ActiveRecord::Base.transaction do
      push_message.push_message_variables.each do |push_message_variable|
        push_message_variable.destroy!
      end
      push_message.destroy!
      render json: { code: 1, message: push_message }
    rescue StandardError => e
      Rails.logger.error(e)
      e.backtrace.each do |line|
        Rails.logger.error(line)
      end
      render json: { code: 2, message: e }
    end
  end

  def subscribe
    push_message = find_push_message(true)
    return if push_message.blank?

    ActiveRecord::Base.transaction do
      push_message.update!(subscribe_status: :subscribe)
      run_schedule_job(push_message)
      render json: { code: 1, message: push_message.subscribe_status }
    rescue StandardError => e
      Rails.logger.error(e)
      e.backtrace.each do |line|
        Rails.logger.error(line)
      end
      render json: { code: 2, message: e }
    end
  end

  def unsubscribe
    push_message = find_push_message(true)
    return if push_message.blank?

    ActiveRecord::Base.transaction do
      push_message.update!(subscribe_status: :unsubscribe)
      run_schedule_job(push_message)
      render json: { code: 1, message: push_message.subscribe_status }
    rescue StandardError => e
      Rails.logger.error(e)
      e.backtrace.each do |line|
        Rails.logger.error(line)
      end
      render json: { code: 2, message: e }
    end
  end

  private

  def push_message_params
    params.require(:push_message).permit(:title, :sending_method, :email_id, :sms_template_id, :started_at,
                                         :has_timezone_exclusion, :excluded_time_from, :excluded_time_to, :alternate_send_time,
                                         :subscribe_status, :last_message_datetime_since)
  end

  def push_message_variable_params(variable)
    variable.permit(:variable_id, :operator, :value)
  end

  def find_chatbot
    unless current_user.admin_deel? || current_user.admin_client?
      render json: { code: 2,
                     message: 'Not have permission' } and return
    end

    chatbot = Chatbot.find_by(id: params[:chatbot_id] || params[:id])
    render json: { code: 2, message: 'Not found chatbot' } and return if chatbot.blank?

    user_chatbot = chatbot.user_chatbots.find_by(chatbot_id: params[:chatbot_id], user: current_user)
    if current_user.admin_client? && user_chatbot.blank?
      render json: { code: 2,
                     message: 'Not have permission' } and return
    end

    chatbot
  end

  def find_push_message(editor_permission = false)
    unless current_user.admin_deel? || current_user.admin_client?
      render json: { code: 2,
                     message: 'Not have permission' } and return
    end

    push_message = PushMessage.find_by(id: params[:id])
    render json: { code: 2, message: 'Not found push message' } and return if push_message.blank?

    chatbot = push_message.chatbot
    render json: { code: 2, message: 'Not found chatbot' } and return if chatbot.blank?

    # user_chatbots = chatbot.user_chatbots.where(chatbot_id: params[:chatbot_id], user: current_user)
    # user_chatbots = user_chatbots.where(role: %i[bot_admin editor]) if editor_permission.present?
    # if current_user.admin_client? && user_chatbots.blank?
    #   render json: { code: 2,
    #                  message: 'Not have permission' } and return
    # end

    push_message
  end

  def run_schedule_job(push_message)
    schedule = DynamicSchedule.find_by(reference_id: push_message.id, job_type: :push_message)
    if schedule.present?
      if push_message.subscribe_status == 'unsubscribe'
        schedule.update!(status: :inactive)
        Sidekiq.remove_schedule(schedule.name)
      elsif push_message.subscribe_status == 'subscribe'
        schedule.update!(status: :active)
        Sidekiq.set_schedule(schedule.name, { class: schedule.class_name,
                                              cron: schedule.cron.to_s,
                                              queue: schedule.priority,
                                              args: schedule.args })
      end
    elsif push_message.subscribe_status == 'subscribe'
      schedule = DynamicSchedule.new({ name: "PushMessageJob-#{push_message.id}",
                                       class_name: 'PushMessageJob',
                                       cron: '*/5 * * * *',
                                       priority: "high",
                                       args: push_message.id.to_s,
                                       status: :active,
                                       job_type: :push_message,
                                       reference_id: push_message.id })
      schedule.save!
      Sidekiq.set_schedule(schedule.name, { class: schedule.class_name,
                                            cron: schedule.cron.to_s,
                                            queue: schedule.priority,
                                            args: schedule.args })
    end
    Sidekiq::Scheduler.reload_schedule!
  end
end
