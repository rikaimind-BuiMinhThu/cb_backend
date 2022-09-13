class Api::V1::MessageManagements::MessageGroupsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    message_groups = MessageGroup.where(user_id: current_user.id)
    total = message_groups.length
    message_groups = message_groups.page(params[:page])
    render json: {code: 1, data: message_groups, total: total}
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
    return render json: {code: 2, message: "Cannot find message group"} if message_group.blank?
    return render json: {code: 2, message: "User can't permission"} if message_group.user_id != current_user.id
    return render json: {code: 1, data: message_group} if message_group_params[:group_name] == message_group.group_name
    if MessageGroup.find_by(group_name: message_group_params[:group_name], user_id: current_user.id)
      render json: {code: 2, message: "Message group name has unique."}
      return
    end
    message_group.update message_group_params
    render json: {code: 1, data: message_group}
  end

  def destroy
    message_group = MessageGroup.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message group"} if message_group.blank?
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
    return render json: {code: 2, message: "Cannot find message group"} if message_group.blank?
    return render json: {code: 2, message: "User can't permission"} if message_group.user_id != current_user.id && HotTemplate.find_by(message_group: message_group).blank?
    ActiveRecord::Base.transaction do
      CopyObject::MessageManager.new(message_group, "group", current_user.id).call
      render json: {code: 1, message: "Success!"}
    rescue StandardError => error
      Rails.logger.debug(error)
      error.backtrace.each do |line|
        Rails.logger.error(line)
      end
      return render json: {code: 2, message: error}
    end
  end

  def export_csv
    @message_group = MessageGroup.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find message group"} if @message_group.blank?
    return render json: {code: 2, message: "User can't permission"} if @message_group.user_id != current_user.id && !current_user.admin_deel?
    instagram_user_group_ids = ChatbotUsage.joins(:chatbot_usage_groups).where("message_group_id = ?", @message_group.id).group(:instagram_user_id).pluck(:instagram_user_id)
    @instagram_users = InstagramUser.where(id: instagram_user_group_ids)
  end

  def data_analyst
    return render json: {code: 2, message: "Cannot find message group"} if current_user.client?
    begin_date = params[:begin_date].to_datetime.at_beginning_of_day() if params[:begin_date].present?
    end_date = params[:end_date].to_datetime.at_end_of_day() if params[:end_date].present?

    q = {}
    q[:created_at_gteq] = begin_date if begin_date.present?
    q[:created_at_lteq] = end_date if end_date.present?
    if current_user.admin_deel?
      @message_groups = MessageGroup.ransack(q).result
      @message_groups = @message_groups.joins(user: :client)
                                       .where('clients.name like ?', "%#{params[:client_name]}%") if params[:client_name].present?
    elsif current_user.admin_client?
      @message_groups = MessageGroup.where(user_id: current_user.id).ransack(q).result
    end
    @total = @message_groups.length
    @message_groups = @message_groups.page(params[:page]).per(10)
    # render json: {code: 1, data: message_groups}
  end

  private

  def message_group_params
    params.require(:message_group).permit(:group_name)
  end
end
