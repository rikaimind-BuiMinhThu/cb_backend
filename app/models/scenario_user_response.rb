class ScenarioUserResponse < ApplicationRecord
  SECRET_KEY = Rails.application.secrets.secret_refresh_token
  belongs_to :scenario

  def self.boolean data_input_name, options={}
    @list ||= {}
    @list[data_input_name] = options.merge(
      value_type: :boolean
    )
  end

  def self.string data_input_name, options={}
    @list ||= {}
    @list[data_input_name] = options.merge(
      value_type: :string
    )
  end

  def self.text data_input_name, options={}
    @list ||= {}
    @list[data_input_name] = options.merge(
      value_type: :text
    )
  end

  def self.integer data_input_name, options={}
    @list ||= {}
    @list[data_input_name] = options.merge(
      value_type: :integer
    )
  end

  def self.list
    @list
  end

  def value=(value)
    payload = {
      exp: (Time.current + 72.hours).to_i
    }
    if self.class.list[self.data_input_name&.to_sym]
      case self.class.list[self.data_input_name.to_sym][:value_type]
      when :boolean
        self.boolean_value = value || false
      when :string
        if self.class.list[self.data_input_name.to_sym][:is_encrypt]
          payload[:data] = value
          value = JWT.encode payload, SECRET_KEY
        end
        self.string_value = value
      when :text
        if self.class.list[self.data_input_name.to_sym][:is_encrypt]
          payload[:data] = value
          value = JWT.encode payload, SECRET_KEY
        end
        self.text_value = value
      when :integer
        self.integer_value = value
      end
    else
      if value.is_a? String
        self.string_value = value
      elsif [true, false].include? value
        self.boolean_value = value
      elsif value.is_a? Integer
        self.integer_value = value
      end
    end
  end

  def value
    if self.class.list[self.data_input_name&.to_sym]
      case self.class.list[self.data_input_name.to_sym][:value_type]
      when :boolean
        self.boolean_value
      when :string
        self.string_value
      when :text
        self.text_value
      when :integer
        self.integer_value
      end
    else
      self.boolean_value || self.string_value || self.integer_value
    end
  end

  def self.build_record(params)
    scenario_id = params[:scenario_id]
    user_id = params[:user_id]
    conversation = params[:message][:message_content].first
    case conversation[:type]
    when 'text_input'
      case conversation[:text_input][:type]
      when 'email_address'
        data_input_name = 'user_email'
        value = conversation.dig(:text_input, :email_address, :value)
      when 'text'
        if params[:message][:message_content].size == 2
          data_input_name = 'data_name'
          value = params[:message][:message_content].to_json
        end
      when 'phone_number'
        data_input_name = 'phone_number'
        value = conversation.dig(:text_input, :phone_number, :value)
      when 'password_confirmation'
        data_input_name = 'user_password'
        value = conversation.dig(:text_input, :password_confirmation, :value)
      end
    when 'zip_code_address'
      data_input_name = 'zip_code_address'
      value = conversation[:zip_code_address].to_json
    when 'radio_button'
      case conversation[:radio_button][:save_input_content]
      when 'is_regular_order'
        value = conversation[:radio_button][:initial_selection] == 1
        data_input_name = 'is_regular_order'
      when "delivery_frequency"
        selected = get_selected_obj_for_radio_button(conversation)
        value = selected[:value]
        data_input_name = 'delivery_frequency'
      when "delivery_method"
        selected = get_selected_obj_for_radio_button(conversation)
        value = selected[:value]
        data_input_name = 'delivery_method'
      when "sex"
        selected = get_selected_obj_for_radio_button(conversation)
        value = selected[:value]
        data_input_name = 'sex'
      end
    when 'card_payment_radio_button'
      selected = get_selected_obj_for_card_payment_radio_button(conversation)

      if conversation[:card_payment_radio_button][:initial_selection] == conversation[:card_payment_radio_button][:card_linked_setting]
        data_input_name = 'credit_card_payment'
        value = conversation[:card_payment_radio_button].to_json
      else
        data_input_name = 'np_delivery_payment'
        value = selected[:value]
      end
    when 'pull_down'
      case conversation[:pull_down][:save_input_content]
      when "birthday" # 誕生日
        value = conversation[:pull_down][:date_ymd].to_json
        data_input_name = "birth_date"
      when "delivery_date" # お届け希望日
        value = get_selected_value_for_pull_down(conversation)
        data_input_name = "delivery_date"
      when "delivery_time" # 時間帯指定
        value = get_selected_value_for_pull_down(conversation)
        data_input_name = "delivery_time"
      when "quantity" # 数量
        selected = get_selected_value_for_pull_down(conversation)
        value = selected.to_i
        data_input_name = "quantity"
      end
    end

    return unless data_input_name.present?
    new_record = self.new(
      scenario_id: scenario_id,
      user_input_id: user_id,
      data_input_name: data_input_name,
      value: value
    )
    new_record
  end

  def self.get_selected_obj_for_radio_button conversation
    selected_id = conversation[:radio_button][:initial_selection]
    conversation[:radio_button][:default].detect{|obj| obj[:id] == selected_id}
  end

  def self.get_selected_obj_for_card_payment_radio_button conversation
    selected_id = conversation[:card_payment_radio_button][:initial_selection]
    conversation[:card_payment_radio_button][:radio_contents].detect{|obj| obj[:id] == selected_id}
  end

  def self.get_selected_value_for_pull_down conversation
    conversation[:pull_down][:customization][:value]
  end

  text :data_name, is_encrypt: false
  text :zip_code_address, is_encrypt: false
  string :phone_number, is_encrypt: false
  string :user_email, is_encrypt: false
  string :user_password, is_encrypt: true
  integer :sex, is_encrypt: false
  text :birth_date, is_encrypt: false
  text :credit_card_payment, is_encrypt: true
  string :cash_on_delivery_payment, is_encrypt: false
  string :np_delivery_payment, is_encrypt: false
  boolean :is_regular_order
  string :delivery_frequency, is_encrypt: false
  integer :quantity, is_encrypt: false
  integer :delivery_method, is_encrypt: false
  string :delivery_date, is_encrypt: false
  string :delivery_time, is_encrypt: false
end
