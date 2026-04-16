class ScenarioUserResponse < ApplicationRecord
  SECRET_KEY = Rails.application.secrets.secret_refresh_token
  belongs_to :scenario

  def self.boolean(data_input_name, options = {})
    @list ||= {}
    @list[data_input_name] = options.merge(
      value_type: :boolean,
    )
  end

  def self.string(data_input_name, options = {})
    @list ||= {}
    @list[data_input_name] = options.merge(
      value_type: :string,
    )
  end

  def self.text(data_input_name, options = {})
    @list ||= {}
    @list[data_input_name] = options.merge(
      value_type: :text,
    )
  end

  def self.integer(data_input_name, options = {})
    @list ||= {}
    @list[data_input_name] = options.merge(
      value_type: :integer,
    )
  end

  def self.list
    @list
  end

  def value=(value)
    payload = {
      exp: (Time.current + 72.hours).to_i,
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
    built_result = []
    puts "-----------------------------------------------------"
    if params[:message][:conditions].present? && params[:message][:conditions].first[:inputCondition] == 'paypal' && params[:message][:message_content].first[:text_input][:save_input_content] != 'pin_code'
      scenario = Scenario.find(scenario_id)
      conversations = scenario.scenario_user_responses.where(user_input_id: user_id)
      condition = params[:message][:conditions].first
      user_response = nil
      user_response = conversations.find_by(data_input_name: 'paypal_payment')
      user_response.update(value: params[:message][:message_content].to_json)
      built_result.push(user_response)
    elsif params[:message][:conditions].present? && params[:message][:conditions].first[:inputCondition] == 'paidy' && params[:message][:message_content].first[:text_input][:save_input_content] != 'pin_code'
      scenario = Scenario.find(scenario_id)
      conversations = scenario.scenario_user_responses.where(user_input_id: user_id)
      condition = params[:message][:conditions].first
      user_response = nil  
      user_response = conversations.find_by(data_input_name: 'paidy_payment')
      user_response.update(value: params[:message][:message_content].to_json)
      built_result.push(user_response)
    else  
      params[:message][:message_content].each do |conversation|
        puts "-----------------------------conversion: #{conversation[:type]}"
        data_input_name = nil
        value = nil
        
        case conversation[:type]
        when "text_input"
          puts "-----------------------------conversion: #{conversation[:text_input][:save_input_content]}"
          case conversation[:text_input][:save_input_content]
          when "user_email"
            data_input_name = "user_email"
            value = conversation.dig(:text_input, :email_address, :value)
          when "email"
            data_input_name = "email"
            value = conversation.dig(:text_input, :email_address, :value)
          when "user_name"
            data_input_name = "user_name"
            if conversation.dig(:text_input, :text, :isSplitInput)
              value = {
                valueLeft: conversation.dig(:text_input, :text, :valueLeft),
                valueRight: conversation.dig(:text_input, :text, :valueRight)
              }.to_json
            else
              value = conversation[:text_input][:text].to_json
            end
          when "user_name_kana"
            data_input_name = "user_name_kana"
            if conversation.dig(:text_input, :text, :isSplitInput)
              value = {
                valueLeft: conversation.dig(:text_input, :text, :valueLeft),
                valueRight: conversation.dig(:text_input, :text, :valueRight)
              }.to_json
            else
              value = conversation[:text_input][:text].to_json
            end
          when "first_name_kana"
            data_input_name = "first_name_kana"
            value = conversation.dig(:text_input, :text, :value)
          when "last_name_kana"
            data_input_name = "last_name_kana"
            value = conversation.dig(:text_input, :text, :value)
          when "phone_number"
            data_input_name = "phone_number"
            if conversation[:text_input][:phone_number][:withHyphen]
              value = conversation[:text_input][:phone_number].to_json
            else
              value = conversation.dig(:text_input, :phone_number, :value)
            end
          when "phone"
            data_input_name = "phone"
            value = conversation.dig(:text_input, :phone_number, :value)
          when "password"
            data_input_name = "password"
            value = conversation.dig(:text_input, :password_confirmation, :value)
          when "quantity"
            data_input_name = "quantity"
            value = conversation.dig(:text_input, :text, :value)
            if value.nil? || value.to_s.strip == ""
              ti = conversation[:text_input]
              tx = ti && ti[:text]
              raw = tx && tx[:value]
              value = (Integer(raw.to_s) rescue nil) if raw != nil && raw.to_s.strip != ""
            end
          when "last_name"
            data_input_name = "last_name"
            value = conversation.dig(:text_input, :text, :value)
          when "first_name"
            data_input_name = "first_name"
            value = conversation.dig(:text_input, :text, :value)
          when "coupons_code"
            data_input_name = "coupons_code"
            value = conversation.dig(:text_input, :text, :value)
          when "pin_code"
            data_input_name = "pin_code"
            value = conversation.dig(:text_input, :text, :value)
          else 
            data_input_name = conversation.dig(:text_input, :type)
            value = self.get_input_text_value(conversation.dig(:text_input))
          end
        when "zip_code_address"
          data_input_name = "zip_code_address"
          value = conversation[:zip_code_address].to_json
        when "agree_term"
          data_input_name = "agree_term"
          value = true
        when "radio_button"
          case conversation[:radio_button][:save_input_content]
          when "is_regular_order"
            value = conversation[:radio_button][:initial_selection] == 1
            data_input_name = "is_regular_order"
          when "has_account"
            selected = get_selected_obj_for_radio_button(conversation)
            value = selected[:value]
            data_input_name = "has_account"
          when "delivery_frequency"
            selected = get_selected_obj_for_radio_button(conversation)
            value = selected[:value]
            data_input_name = "delivery_frequency"
          when "delivery_method"
            selected = get_selected_obj_for_radio_button(conversation)
            value = selected[:value]
            data_input_name = "delivery_method"
          when "payment_method"
            selected = get_selected_obj_for_radio_button(conversation)
            value = selected[:value]
            data_input_name = "payment_method"
          when "sex"
            selected = get_selected_obj_for_radio_button(conversation)
            value = selected[:value]
            data_input_name = "sex"
          when "is_use_coupon"
            selected = get_selected_obj_for_radio_button(conversation)
            value = selected[:value]
            data_input_name = "is_use_coupon"
          when "skip_delivery_datetime"
            data_input_name = "skip_delivery_datetime"
            rb = conversation[:radio_button] || conversation["radio_button"]
            sel = (rb[:initial_selection] || rb["initial_selection"]).to_s
            opts = Array(rb[:default] || rb["default"]) + Array(rb[:radio_button_img] || rb["radio_button_img"])
            hit = opts.find do |o|
              [o[:id], o["id"], o[:value], o["value"]].compact.map(&:to_s).include?(sel)
            end
            raw = hit && (hit[:value] || hit["value"])
            raw = (hit && (hit[:id] || hit["id"])) if raw.nil? && hit
            v = raw.to_s.strip
            value = %w[1 2].include?(v) ? v : "2"
          when "option_variant"
            data_input_name = "option_variant"
            rb = conversation[:radio_button] || conversation["radio_button"]
            value =
              if rb.present? && (rb[:type] || rb["type"]).to_s == "radio_button_img" &&
                  (imgs = rb[:radio_button_img] || rb["radio_button_img"]).present?
                sel = (rb[:initial_selection] || rb["initial_selection"]).to_s
                Array(imgs).find { |x| (x[:value] || x["value"]).to_s == sel }
                  .then { |o| (o && (o[:text] || o["text"] || o[:value] || o["value"]).presence) || sel }
              else
                get_selected_obj_for_radio_button(conversation)&.[](:value)
              end
          when "cross_sell_option"
            data_input_name = "cross_sell_option"
            rb = conversation[:radio_button] || conversation["radio_button"]
            value =
              if rb.present? && (rb[:type] || rb["type"]).to_s == "radio_button_img" &&
                  (imgs = rb[:radio_button_img] || rb["radio_button_img"]).present?
                sel = (rb[:initial_selection] || rb["initial_selection"]).to_s
                Array(imgs).find { |x| (x[:value] || x["value"]).to_s == sel }
                  .then { |o| (o && (o[:text] || o["text"] || o[:value] || o["value"]).presence) || sel }
              else
                v = get_selected_obj_for_radio_button(conversation)&.[](:value)
                if v.nil? && rb.present?
                  sel = (rb[:initial_selection] || rb["initial_selection"]).to_s
                  hit = Array(rb[:default] || rb["default"]).find do |obj|
                    o_id = obj[:id] || obj["id"]
                    o_val = obj[:value] || obj["value"]
                    o_id.to_s == sel || o_val.to_s == sel
                  end
                  v = (hit[:value] || hit["value"]) if hit
                  v = (hit[:id] || hit["id"]) if hit && v.nil?
                end
                v
              end
          end
        when "card_payment_radio_button"
          selected = get_selected_obj_for_card_payment_radio_button(conversation)
          case conversation["card_payment_radio_button"]["initial_selection"]
          when 'credit_card'
            data_input_name = "credit_card_payment"
            value = conversation[:card_payment_radio_button].to_json
          when 'paypal'
            data_input_name = "paypal_payment"
            value = selected[:value]
          when 'komoju'
            data_input_name = "komoju_payment"
            value = conversation[:card_payment_radio_button].to_json
          when 'paidy'
            data_input_name = "paidy_payment"
            value = selected[:value]
          else
            data_input_name = "np_delivery_payment"
            value = selected[:value]
          end
        when "pull_down"
          case conversation[:pull_down][:save_input_content]
          when "birthday" # 誕生日
            value = conversation[:pull_down][:dob_ymd].to_json
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
          when "delivery_method"
            selected = get_selected_value_for_pull_down(conversation)
            value = selected.to_i
            data_input_name = "delivery_method"
          when "country"
            data_input_name = "country"
            value = conversation[:pull_down][:customization][:options_without_comment][0][:value]
          end
        when "textarea"
          puts "-----------------------------conversion: #{conversation[:textarea][:save_input_content]}"
          case conversation[:textarea][:save_input_content]
          when "sent_message"
            data_input_name = "sent_message"
            value = conversation[:textarea][:text_input][:value]
          end
        when "product_purchase_radio_button"
          case conversation[:product_purchase_radio_button][:type]
          when "text_with_thumbnail_image"
            data_input_name = "text_with_thumbnail_image"
            value = conversation[:product_purchase_radio_button].to_json
          end
        when "product_purchase_select_option"
          case conversation[:product_purchase_select_option][:type]
          when "text_with_thumbnail_image"
            data_input_name = "text_with_thumbnail_image"
            value = conversation[:product_purchase_select_option].to_json
          end
        when "calendar"
          calendar = conversation[:calendar] || conversation["calendar"]
          next if calendar.blank?
          is_save = calendar[:is_save_input_content] == true || calendar["is_save_input_content"] == true
          next unless is_save
          data_input_name = (calendar[:save_input_content] || calendar["save_input_content"]).to_s.presence
          next unless data_input_name
          calendar_type = (calendar[:type] || calendar["type"]).to_s
          value = case calendar_type
                  when "start_end_date"
                    s = calendar[:start_date_select] || calendar["start_date_select"]
                    e = calendar[:end_date_select] || calendar["end_date_select"]
                    if s.blank? && e.blank?
                      nil
                    else
                      "#{s.presence || 'start date'} ~ #{e.presence || 'end date'}"
                    end
                  else
                    calendar[:date_select] || calendar["date_select"]
                  end
          next if value.blank?
        end
        puts "=============================="
        puts "data_input_name: #{data_input_name}"
        next unless data_input_name.present?
        new_record = self.new(
          scenario_id: scenario_id,
          user_input_id: user_id,
          data_input_name: data_input_name,
          value: value,
          ui_type: conversation[:type],
          message_id: params[:message][:id],
          submit_type: params[:submit_type],
          message_child_id: conversation[:id],
        )
        built_result.push(new_record)
      end

      built_result
    end
  end
 
  def self.get_input_text_value(text_input_data)
    case text_input_data[:type]
    when 'text'
      if text_input_data.dig(:text, :isSplitInput)
        {
          valueLeft: text_input_data.dig(:text, :valueLeft),
          valueRight: text_input_data.dig(:text, :valueRight)
        }.to_json
      else
        text_input_data.dig(:text).to_json
      end
    when 'urls', 'password', 'email_address', 'email_confirmation', 'password_confirmation'
      text_input_data.dig(text_input_data.dig(:type), :value)
    when 'phone_number'
      type = text_input_data[:type]
      content = text_input_data.dig(type)

      if content&.dig(:withHyphen).present?
        {
          value1: content.dig(:value1),
          value2: content.dig(:value2),
          value3: content.dig(:value3),
        }.to_json
      else
        content&.dig(:value)
      end
    end
  end

  def self.get_selected_obj_for_radio_button(conversation)
    selected_id = conversation[:radio_button][:initial_selection]
    conversation[:radio_button][:default].detect { |obj| obj[:id] == selected_id }
  end

  def self.get_selected_obj_for_card_payment_radio_button(conversation)
    selected_value = conversation[:card_payment_radio_button][:initial_selection]
    conversation[:card_payment_radio_button][:radio_contents].detect { |obj| obj[:value] == selected_value }
  end

  def self.get_selected_value_for_pull_down(conversation)
    selected_text = conversation[:pull_down][:customization][:value]
    selected = conversation[:pull_down][:customization][:options_without_comment].detect { |o| o[:text] == selected_text }
    return selected[:value] if selected.present?
  end

  def self.entry_count_for(scenario_id:, start_date: nil, end_date: nil)
    between(start_date, end_date)
      .where(scenario_id: scenario_id)
      .distinct
      .count(:user_input_id)
  end

  scope :between, ->(start_date, end_date) do
    return all unless start_date || end_date

    if start_date && end_date
      where(created_at: start_date..end_date)
    elsif start_date
      where('created_at >= ?', start_date)
    else
      where('created_at <= ?', end_date)
    end
  end

  text :data_name, is_encrypt: false
  text :zip_code_address, is_encrypt: false
  string :phone_number, is_encrypt: false
  string :user_email, is_encrypt: false
  string :password, is_encrypt: true
  integer :sex, is_encrypt: false
  text :birth_date, is_encrypt: false
  text :credit_card_payment, is_encrypt: true
  string :cash_on_delivery_payment, is_encrypt: false
  string :np_delivery_payment, is_encrypt: false
  boolean :is_regular_order
  string :skip_delivery_datetime
  string :delivery_frequency, is_encrypt: false
  integer :quantity, is_encrypt: false
  integer :delivery_method, is_encrypt: false
  string :delivery_date, is_encrypt: false
  string :delivery_time, is_encrypt: false
  text :komoju_payment, is_encrypt: true
  text :paypal_payment, is_encrypt: true
  text :paidy_payment, is_encrypt: false
  string :pin_code, is_encrypt: false
  string :cross_sell_option, is_encrypt: false
  text :text_with_thumbnail_image, is_encrypt: false
  enum submit_type: {error: 0, add: 1, upd: 2}
end
