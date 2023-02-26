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
    conversion = params[:message][:message_content].first
    case conversion[:type]
    when 'text_input'
      case conversion[:text_input][:type]
      when 'email_address'
        data_input_name = 'user_email'
        value = conversion.dig(:text_input, :email_address, :value)
      when 'text'
        if params[:message][:message_content].size == 2
          data_input_name = 'data_name'
          value = params[:message][:message_content].to_json
        end
      when 'phone_number'
        data_input_name = 'phone_number'
        value = conversion.dig(:text_input, :phone_number, :value)
      when 'password_confirmation'
        data_input_name = 'user_password'
        value = conversion.dig(:text_input, :password_confirmation, :value)
      end
    when 'zip_code_address'
      data_input_name = 'zip_code_address'
      value = conversion[:zip_code_address].to_json
    when 'radio_button'
      case conversion[:radio_button][:save_input_content]
      when 'is_regular_order'
        if conversion[:radio_button][:initial_selection] == 1
          value = true
        else
          value = false
        end
        data_input_name = 'is_regular_order'
      else
        if conversion[:radio_button][:default][0][:text] == "30日ごとに"
          value = "30日ごとに"
          data_input_name = 'delivery_squency'
        elsif conversion[:radio_button][:default][0][:text] == "佐川急便"
          data_input_name = 'delivery_method'
          value = conversion[:radio_button][:initial_selection]
        else
          data_input_name = 'sex'
          value = conversion[:radio_button][:initial_selection]
        end
      end
    when 'card_payment_radio_button'
      if conversion[:card_payment_radio_button][:initial_selection] == conversion[:card_payment_radio_button][:card_linked_setting]
        data_input_name = 'credit_card_payment'
        value = conversion[:card_payment_radio_button].to_json
      else
        data_input_name = 'np_delivery_payment'
        value = 'NP delivery payment'
      end
    when 'pull_down'
      if conversion[:pull_down][:type] == "date_ymd"
        data_date = conversion[:pull_down][:date_ymd]
        value = conversion[:pull_down][:date_ymd].to_json
        data_input_name = 'birth_date'
      elsif conversion[:pull_down][:customization][:title_comment] == "お届け希望日"
        data_input_name = 'delivery_date'
        value = '最短お届け'
      else
        value = conversion[:pull_down][:customization][:value].to_i
        data_input_name = 'quantity'
      end
    end
    new_record = self.new(
      scenario_id: scenario_id,
      user_input_id: user_id,
      data_input_name: data_input_name,
      value: value
    )
    new_record
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
  string :delivery_squency, is_encrypt: false
  integer :quantity, is_encrypt: false
  integer :delivery_method, is_encrypt: false
  string :delivery_date, is_encrypt: false
end
