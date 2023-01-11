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
    return render json: {code: 2, message: "Cannot find chatbot"} if @chatbot.blank?
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
    ActiveRecord::Base.transaction do
      chatbot_dup = chatbot.dup
      chatbot_dup.user_id = current_user.id
      chatbot_dup.icon = chatbot.icon
      chatbot_dup.need_np_deferred_payment = 'no'
      # add validate: false to create chatbot with id, it will rollback if chatbot_dup.save! does not pass in line below
      chatbot_dup.save!(validate: false)
      # chatbot.variables.each do |variable|
      #   variable_dup = variable.dup
      #   chatbot_dup.variables.build(variable_dup.as_json)
      # end
      chatbot.scenarios.each do |scenario|
        scenario_dup = scenario.dup
        chatbot_dup.scenarios.build(scenario_dup.as_json)
      end
      # chatbot.push_messages.each do |push_message|
      #   push_message_dup = push_message.dup
      #   chatbot_dup.push_messages.build(push_message_dup.as_json)
      # end
      # chatbot.history_click_urls.each do |history_click_url|
      #   history_click_url_dup = history_click_url.dup
      #   chatbot_dup.history_click_urls.build(history_click_url_dup.as_json)
      # end
      # chatbot.specify_payment_variables.each do |specify_payment_variable|
      #   specify_payment_variable_dup = specify_payment_variable.dup
      #   chatbot_dup.specify_payment_variables.build(specify_payment_variable_dup.as_json)
      # end
      # chatbot.settlement_fee_variables.each do |settlement_fee_variable|
      #   settlement_fee_variable_dup = settlement_fee_variable.dup
      #   chatbot_dup.settlement_fee_variables.build(settlement_fee_variable_dup.as_json)
      # end
      # chatbot.shipping_fee_variables.each do |shipping_fee_variable|
      #   shipping_fee_variable_dup = shipping_fee_variable.dup
      #   chatbot_dup.shipping_fee_variables.build(shipping_fee_variable_dup.as_json)
      # end
      # chatbot.np_value_settlements.each do |np_value_settlement|
      #   np_value_settlement_dup = np_value_settlement.dup
      #   chatbot_dup.np_value_settlements.build(np_value_settlement_dup.as_json)
      # end

      chatbot_dup.save!

      UserChatbot.create!(user_id: current_user.id,
                          chatbot_id: chatbot_dup.id,
                          role: 'bot_admin')
      render json: {code: 1, data: chatbot_dup}
    rescue StandardError => error
      Rails.logger.debug(error)
      # error.backtrace.each do |line|
      #   Rails.logger.debug(line)
      # end
      return render json: {code: 2, message: error}
    end
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

  def get_design_settings
    chatbot = Chatbot.find_by(id: params[:id])
    return render json: {code: 2, message: "Chatbot not found"} if chatbot.blank?
    design_settings = chatbot.design_settings ? JSON.parse(chatbot.design_settings) : ""
    return render json: { code: 1, data: {
                          design_settings: design_settings,
                          title: chatbot.title,
                          subtitle: chatbot.subtitle,
                          icon: chatbot.icon,
                          main_color: chatbot.main_color} }
  end

  def update_design_settings
    chatbot = Chatbot.find_by(id: params[:id])
    return render json: {code: 2, message: "Chatbot not found"} if chatbot.blank?
    ActiveRecord::Base.transaction do
      chatbot.update!(design_settings: JSON.generate(params[:design_settings].as_json)) if params.present?
      return render json: {code: 1, message: "Success"}
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}
    end
  end

  private

  def chatbot_params
    params.require(:chatbot).permit(:title, :subtitle, :design_type,
      :main_color, :status, :icon, :bot_name)
  end
end



