class Api::V1::Managements::ChatbotsController < ApplicationController

  def index
    chatbots = Chatbot.joins(:user).select("chatbots.*, users.full_name as owner_name") if current_user.admin_deel?
    chatbots = UserChatbot.joins(:chatbot, :user)
                          .select("chatbots.*, user_chatbots.role as my_authority, users.full_name as owner_name")
                          .where(user_id: current_user.id) unless current_user.admin_deel?
    q = {}
    q[:bot_name_cont] = params[:name] if params[:name].present?
    q[:status_eq] = (params[:status] == 'on') ? 1 : 0 if params[:status].present? && (params[:status] == 'on' || params[:status] == 'off')
    q_ac = {}
    q_ac[:chatbot_bot_name_cont] = params[:name] if params[:name].present?
    q_ac[:chatbot_status_eq] = (params[:status] == 'on') ? 1 : 0 if params[:status].present? && (params[:status] == 'on' || params[:status] == 'off')
    chatbots = chatbots.ransack(q).result(distinct: true) if current_user.admin_deel?
    chatbots = chatbots.ransack(q_ac).result(distinct: true) unless current_user.admin_deel?
    total = chatbots.length
    chatbots = chatbots.page(params[:page]).per(10)
    unless current_user.admin_deel?
      chatbots.each do |chatbot|
        chatbot.status = chatbot.status == 0 ? 'off' : 'on'
      end
    end
    render json: {code: 1, data: chatbots, total: total}
  end

  def show
    return render json: {code: 2, message: "No permission"} unless UserChatbot.find_by(user_id: current_user.id, chatbot_id: params[:id]).present? || current_user.admin_deel?
    @chatbot = Chatbot.joins({user_chatbots: :user}).select("chatbots.*, users.full_name as owner_name")
                     .find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find chatbot"} if @chatbot.blank?
  end

  def create
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    chatbot = Chatbot.new(chatbot_params)
    chatbot.user = current_user
    chatbot.status = :off
    ActiveRecord::Base.transaction do
      chatbot.save!
      UserChatbot.create!(user: current_user, chatbot: chatbot, role: :bot_admin)
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, data: chatbot}
  end

  def update
    chatbot = Chatbot.find_by(id: params[:id])
    return render json: {code: 2, message: "Chatbot not found"} if chatbot.blank?
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.id == chatbot.user_id
    ActiveRecord::Base.transaction do
      chatbot.update!(chatbot_params)
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, data: chatbot}
  end

  def destroy
    chatbot = Chatbot.find_by(id: params[:id])
    return render json: {code: 2, message: "Chatbot not found"} if chatbot.blank?
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.id == chatbot.user_id
    ActiveRecord::Base.transaction do
      user_chatbots = UserChatbot.where(chatbot_id: params[:id]).destroy_all
      chatbot.destroy!
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, message: "Success"}
  end

  def duplicate
    chatbot = Chatbot.find_by(id: params[:id])
    return render json: {code: 2, message: "Chatbot not found"} if chatbot.blank?
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.id == chatbot.user_id
    chatbot_dup = chatbot.dup
    chatbot_dup.user_id = current_user.id
    ActiveRecord::Base.transaction do
      chatbot_dup.save!
      UserChatbot.create!(user_id: current_user.id,
                          chatbot_id: chatbot_dup.id,
                          role: 'bot_admin')
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, data: chatbot_dup}
  end

  def scenario_selected
    chatbot = Chatbot.find_by(id: params[:id])
    return render json: {code: 2, message: "Chatbot not found"} if chatbot.blank?
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel? || current_user.id == chatbot.user_id
    return render json: {code: 2, message: "Scenario not found"} if Scenario.find_by(id: params[:scenario_selected]).blank?
    ActiveRecord::Base.transaction do
      chatbot.update! scenario_selected: params[:scenario_selected]
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
    render json: {code: 1, data: chatbot}
  end

  def get_list_chatbot_by_client
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    user_ids = User.admin_client.where(client_id: params[:client_id]).pluck(:id)
    chatbots = Chatbot.select(:id, :bot_name)
                      .where("user_id in (?)", user_ids)
    render json: {code: 1, data: chatbots}
  end

  private

  def chatbot_params
    params.require(:chatbot).permit(:title, :subtitle, :design_type,
      :main_color, :status, :icon, :bot_name)
  end
end



