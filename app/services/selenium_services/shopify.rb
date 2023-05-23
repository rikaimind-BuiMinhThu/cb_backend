require "selenium-webdriver"
require File.dirname(__FILE__) + "/../log"

module SeleniumServices
  class Shopify < Base
    QUANLITY_INPUT = "input.quantity__input"
    ADD_TO_CART_BUTTON = "button[name=add]"

    CART_ANCHOR = "a[id=cart-icon-bubble]"
    CHECKOUT_BUTTON = "button#checkout"

    EMAIL_INPUT = "input#email"
    COUNTRY_SELECT = "select[name=countryCode]"
    LAST_NAME_INPUT = "input[name=lastName]"
    FIRST_NAME_INPUT = "input[name=firstName]"
    POSTAL_CODE_INPUT = "input#postalCode"
    CITY_INPUT = "input[name=city]"
    ADDRESS_INPUT = "input[name=address1]"
    APARTMENT_INPUT = "input[name=address2]"
    CHECKOUT_SUBMIT_BUTTON = "button[type=submit]"

    PAYMENT_SUBMIT_BUTTON = "button[type=submit]"

    SHOPIFY_PAYMENT_CREDIT_CARD_LABEL = "label[for=basic-creditCards]"
    SHOPIFY_PAYMENT_CARD_NUMBER_INPUT = "input[name=number]:not(:-webkit-autofill)"
    SHOPIFY_PAYMENT_NAME_ON_CARD_INPUT = "input#name"
    SHOPIFY_PAYMENT_EXPIRY_DATE_INPUT = "input#expiry"
    SHOPIFY_PAYMENT_SECURITY_CODE_INPUT = "input#verification_value"

    PAYPAL_PAYMENT_LABEL = "label[for=basic-PAYPAL_EXPRESS]"
    PAYPAL_PAYMENT_WITH_ANOTHER_METHOD = "a[class=scTrack:tryAnotherWayLink]"
    PAYPAL_PAYMENT_WITH_ANOTHER_METHOD_BUTTON = "a[id=loginWithPassword]"
    PAYPAL_PAYMENT_BUTTON = "div[id=buttons-container][aria-label=PayPal]"
    PAYPAL_PAYMENT_EMAIL_INPUT = "input#email"
    PAYPAL_PAYMENT_NEXT_BUTTON = "button#btnNext"
    PAYPAL_PAYMENT_PASSWORD_INPUT = "input#password"
    PAYPAL_PAYMENT_LOGIN_BUTTON = "button#btnLogin"
    PAYPAL_PAYMENT_CHECKOUT_BUTTON = "button#payment-submit-btn"

    KOMOJU_PAYMENT_CREDIT_CARD_LABEL = "label[for=basic-Credit / Debit Card]"
    KOMOJU_PAYMENT_CARD_NUMBER_INPUT = "input[name=number]:not(:-webkit-autofill)"
    KOMOJU_PAYMENT_NAME_ON_CARD_INPUT = "input#name"
    KOMOJU_PAYMENT_EXPIRY_DATE_INPUT = "input#expiration"
    KOMOJU_PAYMENT_SECURITY_CODE_INPUT = "input#verification"
    KOMOJU_PAY_NOW_BUTTON = "input[type=submit]"

    PAIDY_PAYMENT_LABEL = "label[for=basic-あと払い（ペイディ）]"
    PAIDY_PAYMENT_EMAIL_INPUT = "input#ip_email"
    PAIDY_PAYMENT_PHONE_INPUT = "input#ip_phone"
    PAIDY_PAYMENT_NEXT_BUTTON = "button#btn_login"
    PAIDY_PAYMENT_INPUT_PIN_0 = "input#input_pin_0"
    PAIDY_PAYMENT_INPUT_PIN_1 = "input#input_pin_1"
    PAIDY_PAYMENT_INPUT_PIN_2 = "input#input_pin_2"
    PAIDY_PAYMENT_INPUT_PIN_3 = "input#input_pin_3"
    PAIDY_PAYMENT_SELECT_PAYMENT_OPTIONS = "#root"
    PAIDY_PAYMENT_SELECT_SINGLE_PAY = "div[testid=npay-select-option-single_pay]"
    PAIDY_PAYMENT_NEXT_CONFIRM = "button#btn_multi_confirm_next"

    PAY_NOW_BUTTON = "button[type=submit]"

    def process
      @log_tab_level += 1
      Log.info "Start process", @log_tab_level

      begin
        product_page
        cart_page
        checkout_page
        entry_checkout_information
        confirm_page
        payment_page
        quit

        @selenium_result.update! result: :done, end_time: DateTime.now, last_step_no: @step
      rescue => e
        Log.error e.message
        Log.error e.backtrace.join("\n\t")
        @is_error = true

        capture true

        quit
        @selenium_result.update! result: :error, end_time: DateTime.now, last_step_no: @step
      end
    end

    private

    def product_page
      @log_tab_level += 1
      Log.info "product_page", @log_tab_level
      navigate @scenario.landing_page_product_url
      wait_element_load ADD_TO_CART_BUTTON

      if quantity_value.present?
        fill_to_text_input QUANLITY_INPUT, quantity_value, "Fill-in quantity", true
      end

      capture
      click ADD_TO_CART_BUTTON, "Add product to cart"
    end

    def cart_page
      @log_tab_level += 1
      Log.info "cart_page", @log_tab_level
      wait_element_load CART_ANCHOR
      capture
      click CART_ANCHOR, "Click cart anchor"
    end

    def checkout_page
      @log_tab_level += 1
      Log.info "checkout_page", @log_tab_level
      wait_element_load CHECKOUT_BUTTON
      capture
      click CHECKOUT_BUTTON, "Click checkout button"
    end

    def entry_checkout_information
      @log_tab_level += 1
      Log.info "entry_checkout_information", @log_tab_level
      wait_element_load EMAIL_INPUT
      fill_to_text_input EMAIL_INPUT, @user_email, "Fill-in user email"
      fill_to_text_input LAST_NAME_INPUT, @last_name, "Fill-in last name"
      fill_to_text_input FIRST_NAME_INPUT, @first_name, "Fill-in first name"
      select COUNTRY_SELECT, @country, "", "Select country name"
      fill_to_text_input POSTAL_CODE_INPUT, @post_code, "Fill-in post code"
      fill_to_text_input CITY_INPUT, @data_address["value_municipality"], "Fill-in city name"
      fill_to_text_input ADDRESS_INPUT, @data_address["value_address"], "Fill-in address"
      fill_to_text_input APARTMENT_INPUT, @data_address["value_building_name"], "Fill-in building name"
      capture
      click CHECKOUT_SUBMIT_BUTTON, "Click checkout submit button"
    end

    def confirm_page
      @log_tab_level += 1
      Log.info "confirm_page", @log_tab_level
      wait_element_load PAYMENT_SUBMIT_BUTTON
      capture
      click PAYMENT_SUBMIT_BUTTON, "Click payment submit button"
    end

    def payment_page
      @log_tab_level += 1
      Log.info "confirm_page", @log_tab_level
      wait_element_load(PAYMENT_SUBMIT_BUTTON)
      capture()
      # TODO check payment method
      if @credit_card_payment.present?
        entry_credit_payment_information()
      elsif @paypal_payment.present?
        entry_paypal_payment_information()
      elsif @komoju_payment.present?
        entry_komoju_payment_information()
      elsif @paidy_payment.present?
        entry_paidy_payment_information()
      end
    end

    def entry_paidy_payment_information
      email = ''
      phone_number = ''
      @paidy_data.each do |conversation|
        case conversation[:type]
        when "text_input"
          puts "-----------------------------conversion: #{conversation[:text_input][:save_input_content]}"
          case conversation[:text_input][:save_input_content]
          when "user_email"
            email = conversation.dig(:text_input, :email_address, :value)
          when "phone_number"
            phone_number = conversation.dig(:text_input, :phone_number, :value)
          end
      end

      @log_tab_level += 1
      Log.info "entry_paidy_payment_information", @log_tab_level
      wait_element_load PAIDY_PAYMENT_LABEL
      click PAIDY_PAYMENT_LABEL, "Click paidy option"
      click PAY_NOW_BUTTON, "Click pay now button"

      # switch to paidy tab
      @driver.switch_to.window driver.window_handles.at(1)

      # input email
      wait_element_load PAIDY_PAYMENT_EMAIL_INPUT
      element = @driver.find_element(:css, PAIDY_PAYMENT_EMAIL_INPUT)
      element.clear
      fill_to_text_input PAIDY_PAYMENT_EMAIL_INPUT, email, "Fill-in user email"

      # input password
      wait_element_load PAIDY_PAYMENT_PHONE_INPUT
      fill_to_text_input PAIDY_PAYMENT_PHONE_INPUT, phone_number, "Fill-in phone number"

      # click login
      wait_element_load PAIDY_PAYMENT_NEXT_BUTTON
      click PAIDY_PAYMENT_NEXT_BUTTON, "Click login paypal"

      #input pincode
      pin_code = @pin_code.split('')
      sleep 60
      wait_element_load PAIDY_PAYMENT_INPUT_PIN_0
      fill_to_text_input PAIDY_PAYMENT_INPUT_PIN_0, pin_code[0], "Fill-in pin 0"
      fill_to_text_input PAIDY_PAYMENT_INPUT_PIN_1, pin_code[1], "Fill-in pin 1"
      fill_to_text_input PAIDY_PAYMENT_INPUT_PIN_2, pin_code[2], "Fill-in pin 2"
      fill_to_text_input PAIDY_PAYMENT_INPUT_PIN_3, pin_code[3], "Fill-in pin 3"

      # click checkout
      wait_element_load PAIDY_PAYMENT_SELECT_SINGLE_PAY
      click PAIDY_PAYMENT_SELECT_SINGLE_PAY, "Click select single pay"

      #confirm payment
      wait_element_load PAIDY_PAYMENT_NEXT_CONFIRM
      click PAIDY_PAYMENT_NEXT_CONFIRM, "Click select single pay"

      wait_element_load PAIDY_PAYMENT_NEXT_CONFIRM
      click PAIDY_PAYMENT_NEXT_CONFIRM, "Click select single pay"

      @driver.switch_to.default_content
    end

    def entry_paypal_payment_information
      email = ''
      password = ''
      @paypal_data.each do |conversation|
        case conversation[:type]
        when "text_input"
          puts "-----------------------------conversion: #{conversation[:text_input][:save_input_content]}"
          case conversation[:text_input][:save_input_content]
          when "user_email"
            email = conversation.dig(:text_input, :email_address, :value)
          when "password"
            password = conversation.dig(:text_input, :password_confirmation, :value)
          end
      end

      @log_tab_level += 1
      Log.info "entry_paypal_payment_information", @log_tab_level
      wait_element_load PAYPAL_PAYMENT_LABEL
      click PAYPAL_PAYMENT_LABEL, "Click paypal option"
      click PAY_NOW_BUTTON, "Click pay now button"
      # switch to paypal tab
      @driver.switch_to.window driver.window_handles.at(1)

      if @driver.find_elements(id: "otpVerification").size() > 0
        click PAYPAL_PAYMENT_WITH_ANOTHER_METHOD, 'switch to another payment method'
        wait_element_load PAYPAL_PAYMENT_WITH_ANOTHER_METHOD_BUTTON
        click PAYPAL_PAYMENT_WITH_ANOTHER_METHOD_BUTTON, 'switch to another payment method button'
      end

      # input email
      wait_element_load PAYPAL_PAYMENT_EMAIL_INPUT
      element = @driver.find_element(:css, PAYPAL_PAYMENT_EMAIL_INPUT)
      element.clear
      fill_to_text_input PAYPAL_PAYMENT_EMAIL_INPUT, email, "Fill-in user email"

      # click next
      wait_element_load PAYPAL_PAYMENT_NEXT_BUTTON
      click PAYPAL_PAYMENT_NEXT_BUTTON, "Click next paypal"

      # input password
      wait_element_load PAYPAL_PAYMENT_PASSWORD_INPUT
      fill_to_text_input PAYPAL_PAYMENT_PASSWORD_INPUT, password, "Fill-in user email"
    
      # click login
      wait_element_load PAYPAL_PAYMENT_LOGIN_BUTTON
      click PAYPAL_PAYMENT_LOGIN_BUTTON, "Click login paypal"

      # click checkout
      wait_element_load PAYPAL_PAYMENT_CHECKOUT_BUTTON
      click PAYPAL_PAYMENT_CHECKOUT_BUTTON, "Click checkout paypal"

      @driver.switch_to.default_content
    end

    def entry_komoju_payment_information
      @log_tab_level += 1
      Log.info "entry_komoju_payment_information", @log_tab_level
      wait_element_load KOMOJU_PAYMENT_CREDIT_CARD_LABEL
      click KOMOJU_PAYMENT_CREDIT_CARD_LABEL, "Click komoju card option"

      # enter card number
      wait_element_load "#session"
      wait_element_load KOMOJU_PAYMENT_CARD_NUMBER_INPUT
      @card_data["card_number"].split(//).map do |each|
        fill_to_text_input KOMOJU_PAYMENT_CARD_NUMBER_INPUT, each.to_i, "card_number"
      end
      @driver.switch_to.default_content

      # enter card name
      wait_element_load KOMOJU_PAYMENT_NAME_ON_CARD_INPUT
      @card_data["card_holder"].split(//).map do |each|
        fill_to_text_input KOMOJU_PAYMENT_NAME_ON_CARD_INPUT, each, "card_name"
      end
      @driver.switch_to.default_content

      # enter card date
      wait_element_load KOMOJU_PAYMENT_EXPIRY_DATE_INPUT
      expiry_date = @card_data["month"].to_s + @card_data["year"].to_s
      expiry_date.split(//).map do |each|
        fill_to_text_input KOMOJU_PAYMENT_EXPIRY_DATE_INPUT, each.to_i, "card_name"
      end
      @driver.switch_to.default_content

       # enter card code
      wait_element_load KOMOJU_PAYMENT_SECURITY_CODE_INPUT
      @card_data["cvc"].to_s.split(//).map do |each|
        fill_to_text_input KOMOJU_PAYMENT_SECURITY_CODE_INPUT, each.to_i, "cvc"
      end
      @driver.switch_to.default_content

      capture
      click KOMOJU_PAY_NOW_BUTTON, "Click pay now button"
    end

    def entry_credit_payment_information
      @log_tab_level += 1
      Log.info "entry_credit_payment_information", @log_tab_level
      wait_element_load SHOPIFY_PAYMENT_CREDIT_CARD_LABEL
      click SHOPIFY_PAYMENT_CREDIT_CARD_LABEL, "Click credit card option"

      # enter card number
      wait_element_load "iframe.card-fields-iframe[id^=card-fields-number]"
      @driver.switch_to.frame driver.find_element(:css, "iframe.card-fields-iframe[id^=card-fields-number]")
      wait_element_load SHOPIFY_PAYMENT_CARD_NUMBER_INPUT
      @card_data["card_number"].split(//).map do |each|
        fill_to_text_input SHOPIFY_PAYMENT_CARD_NUMBER_INPUT, each.to_i, "card_number"
      end
      @driver.switch_to.default_content

      # enter card name
      wait_element_load "iframe.card-fields-iframe[id^=card-fields-name]"
      @driver.switch_to.frame driver.find_element(:css, "iframe.card-fields-iframe[id^=card-fields-name]")
      @card_data["card_holder"].split(//).map do |each|
        fill_to_text_input SHOPIFY_PAYMENT_NAME_ON_CARD_INPUT, each, "card_name"
      end
      @driver.switch_to.default_content

      # enter card date
      wait_element_load "iframe.card-fields-iframe[id^=card-fields-expiry]"
      @driver.switch_to.frame driver.find_element(:css, "iframe.card-fields-iframe[id^=card-fields-expiry]")
      expiry_date = @card_data["month"].to_s + @card_data["year"].to_s
      expiry_date.split(//).map do |each|
        fill_to_text_input SHOPIFY_PAYMENT_EXPIRY_DATE_INPUT, each.to_i, "card_name"
      end
      @driver.switch_to.default_content

       # enter card code
      wait_element_load "iframe.card-fields-iframe[id^=card-fields-verification]"
      @driver.switch_to.frame driver.find_element(:css, "iframe.card-fields-iframe[id^=card-fields-verification]")
      @card_data["cvc"].to_s.split(//).map do |each|
        fill_to_text_input SHOPIFY_PAYMENT_SECURITY_CODE_INPUT, each.to_i, "cvc"
      end
      @driver.switch_to.default_content

      capture
      click PAY_NOW_BUTTON, "Click pay now button"
    end

    def fill_to_text_input(css_selector, value, description = "", clear_input = false, pointer_action: true)
      @log_tab_level += 1
      Log.info "Fill to text input #{css_selector}: #{description}", @log_tab_level
      Log.info "input_element = @driver.find_element(css: #{css_selector})", @log_tab_level + 1
      input_element = @driver.find_element(css: css_selector)
      Log.info "input_element.send_keys(#{value})", @log_tab_level + 1
      input_element.clear if clear_input
      input_element.send_keys(value)
      capture
      @log_tab_level -= 1
      @driver.action.pointer_down(:left).pointer_up(:left).perform if pointer_action
    end

    def extract_conversions_data
      @quantity_value = find_response_by_data_input_name("quantity")
      @user_email = find_response_by_data_input_name("user_email")
      encrypted_password_value = find_response_by_data_input_name("user_password")
      @password_value = JWT.decode(encrypted_password_value, SECRET_KEY)[0]["data"]
      @country = find_response_by_data_input_name("country")
      @last_name = find_response_by_data_input_name("last_name")
      @pin_code = find_response_by_data_input_name("pin_code")
      @first_name = find_response_by_data_input_name("first_name")
      @data_address = JSON.parse find_response_by_data_input_name("zip_code_address")
      @post_code = @data_address["value_post_code"].gsub("-", "")
      @credit_card_payment = find_response_by_data_input_name("credit_card_payment")
      @card_data = JSON.parse(JWT.decode(@credit_card_payment, SECRET_KEY)[0]["data"]) if @credit_card_payment.present?
      @paypal_payment = find_response_by_data_input_name("paypal_payment")
      @paypal_data = JSON.parse(JWT.decode(@paypal_payment, SECRET_KEY)[0]["data"]) if @paypal_payment.present?
      @komoju_payment = find_response_by_data_input_name("komoju_payment")
      @komoju_data = JSON.parse(JWT.decode(@komoju_payment, SECRET_KEY)[0]["data"]) if @komoju_payment.present?
      @paidy_payment = find_response_by_data_input_name("paidy_payment")
      @paidy_data = JSON.parse(@paidy_payment) if @paidy_payment.present?
    end
  end
end
