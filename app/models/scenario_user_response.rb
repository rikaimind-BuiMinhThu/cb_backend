class ScenarioUserResponse < ApplicationRecord
  # belongs_to :scenario

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
    if self.class.list[self.data_input_name.to_sym]
      case self.class.list[self.data_input_name.to_sym][:value_type]
      when :boolean
        self.boolean_value = value
      when :string
        if self.class.list[self.data_input_name.to_sym][:is_encrypt]
          value = JWT.encode value, Rails.application.secrets.secret_refresh_token
        end
        self.string_value = value
      when :integer
        self.integer_value = value
      end
    end
  end

  def value
    if self.class.list[self.data_input_name.to_sym]
      case self.class.list[self.data_input_name.to_sym][:value_type]
      when :boolean
        self.boolean_value
      when :string
        self.string_value
      when :integer
        self.integer_value
      end
    else
      nil
    end
  end

  string :family_name, is_encrypt: false
  string :first_name, is_encrypt: false
  string :family_name_kana, is_encrypt: false
  string :first_name_kana, is_encrypt: false
  string :zip_code, is_encrypt: false
  string :shipping_address, is_encrypt: false
  string :address_pref, is_encrypt: false
  string :city, is_encrypt: false
  string :address, is_encrypt: false
  string :building, is_encrypt: false
  string :tel, is_encrypt: false
  string :user_email, is_encrypt: false
  string :user_password, is_encrypt: true
  string :sex, is_encrypt: false
  string :birth_date, is_encrypt: false
  string :payment_method, is_encrypt: false
  string :card_number, is_encrypt: true
  string :card_name, is_encrypt: true
  string :security_code, is_encrypt: true
  string :card_brand, is_encrypt: true
  string :comment, is_encrypt: false
  boolean :is_use_point, is_encrypt: false
  string :coupon, is_encrypt: false
  string :delivery, is_encrypt: false
  boolean :is_send_to_registered_address, is_encrypt: false
end
