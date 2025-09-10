class Api::V1::Managements::ScenariosController < ApplicationController
  skip_before_action :permision, only: [:preview, :get_scenario_selected]
  skip_before_action :verify_authenticity_token, only: [:preview, :get_scenario_selected]
  before_action :check_chatbot_present, except: [:preview, :get_scenario_selected, :get_list_scenario_by_client]

  SCAN_REGEX = /\{\{(.*?)\}\}/

  def index
    scenarios = Scenario.where(chatbot_id: params[:chatbot_id])
    total = scenarios.length
    scenarios = scenarios.page(params[:page])
    render json: {code: 1, data: scenarios, total: total, scenario_selected: @chatbot.scenario_selected}
  end

  def show
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"} if scenario.blank?
    render json: {code: 1, data: scenario}
  end

  def preview
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"} if scenario.blank?
    scenario_conversation = scenario.conversation
    # variables = Variable.where(variable_name: scenario_conversation.scan(/\{\{(.*?)\}\}/).flatten).each do |variable|
    #   scenario_conversation.gsub!("{{#{variable.variable_name}}}", variable.default_value)
    # end
    variables = Variable.select(:variable_name, :default_value)
                        .where(chatbot_id: scenario.chatbot_id)
                        .where(variable_name: scenario_conversation.scan(/\{\{(.*?)\}\}/).flatten) if scenario_conversation.present?

    all_variables = Variable.select(:variable_name, :default_value)
                            .where(chatbot_id: scenario.chatbot_id)

    chatbot = Chatbot.select(:id, :main_color, :main_color_other, :icon, :opening_bot_icon, :closing_bot_icon, :title, :subtitle, :withdrawal_prevention_status,
                             :withdrawal_prevention_link_url, :withdrawal_prevention_image_url, :design_settings, :user_id)
                     .find_by(id: scenario.chatbot_id)


    client_cart_system = Client.get_cart_system_by_user_id(chatbot.user_id) if chatbot.user_id

    render json: {
      code: 1,
      data: {
        id: scenario.id,
        name: scenario.name,
        chatbot_id: scenario.chatbot_id,
        conversation: scenario_conversation ? JSON.parse(scenario_conversation) : "",
        created_at: scenario.created_at,
        updated_at: scenario.updated_at
      },
      variables: variables ? variables : "",
      chatbot: {
        id: chatbot.id,
        main_color: chatbot.main_color,
        main_color_other: chatbot.main_color_other,
        icon: chatbot.icon,
        title: chatbot.title,
        subtitle: chatbot.subtitle,
        withdrawal_prevention_status: chatbot.withdrawal_prevention_status,
        withdrawal_prevention_link_url: chatbot.withdrawal_prevention_link_url,
        withdrawal_prevention_image_url: chatbot.withdrawal_prevention_image_url,
        is_used_custom_css: scenario.is_used_custom_css,
        custom_css_content: scenario.custom_css_content,
        is_used_err_msg_by_js: scenario.is_used_err_msg_by_js,
        err_msg_js_code: scenario.err_msg_js_code,
        is_used_custom_js_code: scenario.is_used_custom_js_code,
        timer_config: scenario.timer_config ? JSON.parse(scenario.timer_config) : "",
        head_custom_js_code: scenario.head_custom_js_code,
        top_body_custom_js_code: scenario.top_body_custom_js_code,
        bottom_body_custom_js_code: scenario.bottom_body_custom_js_code,
        client_cart_system: client_cart_system,
        is_used_message_loaded_past: scenario.is_used_message_loaded_past,
        opening_bot_icon: chatbot.opening_bot_icon,
        closing_bot_icon: chatbot.closing_bot_icon,
        use_fullwidth_chatbot_mobile: scenario.use_fullwidth_chatbot_mobile
      },
      all_variables: all_variables,
      design_settings: chatbot.design_settings ? JSON.parse(chatbot.design_settings) : ""
    }
  end

  def create
    scenario = Scenario.new(scenario_params)
    scenario.chatbot_id = params[:chatbot_id]
    ActiveRecord::Base.transaction do
      scenario.save!
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}, status: 500
    end
    render json: {code: 1, data: scenario}
  end

  def update
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"}, status: 404 if scenario.blank?
    ActiveRecord::Base.transaction do
      scenario.update!(scenario_params)
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}, status: 500
    end
    render json: {code: 1, data: scenario}
  end

  def destroy
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"}, status: 404 if scenario.blank?
    ActiveRecord::Base.transaction do
      scenario.destroy!
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}, status: 500
    end
    render json: {code: 1, message: "Success"}
  end

  def detail_conversation
    @scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"}, status: 404 if @scenario.blank?
    @client = @scenario.chatbot.user.client
    @landing_page_product_url = @client.respond_to?(:tamago_repeat) ? @scenario.tamago_repeat_config&.tamago_landing_page_url : @scenario.landing_page_product_url
  end

  def conversation
    @scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"}, status: 404 if @scenario.blank?
    client = @chatbot.user.client
    ActiveRecord::Base.transaction do
      build_tamago_repeat_config if client.respond_to?(:tamago_repeat)
      if params["landing_page_product_url"].present?
        @scenario.landing_page_product_url = params["landing_page_product_url"]
      else
        @scenario.landing_page_product_url = params["landing_page_product_url"]
      end
      @scenario.conversation = JSON.generate(params[:conversation].as_json) if params[:conversation].present?
      @scenario.name = params[:scenario_name]
      @scenario.is_use_only_regular_order = params[:is_use_only_regular_order]
      @scenario.is_used_fukushashiki = params[:is_used_fukushashiki]
      @scenario.is_used_custom_css = params[:is_used_custom_css]
      @scenario.custom_css_content = params[:custom_css_content]
      @scenario.is_used_err_msg_by_js = params[:is_used_err_msg_by_js]
      @scenario.err_msg_js_code = params[:err_msg_js_code]
      @scenario.is_used_custom_js_code = params[:is_used_custom_js_code]
      @scenario.head_custom_js_code = params[:head_custom_js_code]
      @scenario.top_body_custom_js_code = params[:top_body_custom_js_code]
      @scenario.bottom_body_custom_js_code = params[:bottom_body_custom_js_code]
      @scenario.timer_config = JSON.generate(params[:timer_config].as_json) if params[:timer_config].present?
      @scenario.is_used_message_loaded_past = params[:is_used_message_loaded_past]
      @scenario.use_fullwidth_chatbot_mobile = params[:use_fullwidth_chatbot_mobile]
      @scenario.save!
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}, status: 500
    end
  end

  def duplicate
    scenario = Scenario.find_by(id: params[:id])
    return render json: {code: 2, message: "Scenario not found"}, status: 404 if scenario.blank?
    scenario_dup = scenario.dup
    if Scenario.find_by(name: scenario.name + " (1)",
                        chatbot_id: params[:chatbot_id]).present?
      index = 1
      loop do
        index += 1
        temp_message = Scenario.find_by(name: scenario.name + " (#{index})",
                                chatbot_id: params[:chatbot_id])
        break if temp_message.blank?
      end
      scenario_dup.name = scenario.name + " (#{index})"
    else
      scenario_dup.name = scenario.name + " (1)"
    end
    ActiveRecord::Base.transaction do
      scenario_dup.save!
    rescue StandardError => error
      Rails.logger.debug(error)
      return render json: {code: 2, message: error}, status: 500
    end
    render json: {code: 1, data: scenario}
  end

  def get_all
    scenarios = Scenario.select(:id, :name)
                        .where(chatbot_id: params[:chatbot_id])
    render json: {code: 1, data: scenarios}
  end

  def get_scenario_selected
    bot = Chatbot.find_by(id: params[:chatbot_id])     
    return render json: { code: 2, message: "Chatbot not found" } if bot.blank?  
    scenario = Scenario.select(:id, :name).find_by(id: bot.scenario_selected)  
    if scenario.blank?
      return render json: { code: 2, message: "Scenario not found" }
    end  
    render json: { code: 1, data: scenario, cart_system: bot.user&.client&.cart_system }
  end

  def get_list_scenario_by_client
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    user_ids = User.admin_client.where(client_id: params[:client_id]).pluck(:id)
    chatbot_ids = Chatbot.where("user_id in (?)", user_ids).pluck(:id)
    return render json: {code: 2, message: "No data"} if chatbot_ids.length == 0
    scenarios = Scenario.select(:id, :name)
                        .where("chatbot_id in (?)", chatbot_ids)
    render json: {code: 1, data: scenarios}
  end

  private

  def scenario_params
    params.require(:scenario).permit(:name)
  end

  def build_tamago_repeat_config
    if @scenario.tamago_repeat_config.nil?
      @scenario.build_tamago_repeat_config
    end

    @scenario.tamago_repeat_config.tamago_landing_page_url = params[:landing_page_product_url] if params[:landing_page_product_url].present?
    @scenario.tamago_repeat_config.add_to_cart_button_selector = params[:add_to_cart_button_selector] if params[:add_to_cart_button_selector].present?
    @scenario.tamago_repeat_config.email_confirm_field = params[:email_confirm_field] if params[:email_confirm_field].present?
    @scenario.tamago_repeat_config.name_kana_field = params[:name_kana_field] if params[:name_kana_field].present?
    @scenario.tamago_repeat_config.save!
  end

  def check_chatbot_present
    @chatbot = Chatbot.find_by(id: params[:chatbot_id])
    return render json: {code: 2, message: "Chatbot not found"} if @chatbot.blank?
    user_chatbot = UserChatbot.find_by(user_id: current_user.id, chatbot_id: params[:chatbot_id])
    return render json: {code: 2, message: "No permission"} if (user_chatbot.blank? || user_chatbot.reader?)
  end
end
