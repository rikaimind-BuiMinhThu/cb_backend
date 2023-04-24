require "selenium-webdriver"
require File.dirname(__FILE__) + "/../log"

module SeleniumServices
  class SubscStore < Base
    QUANLITY_INPUT = "select"
    ADD_TO_CART_BUTTON = "a[class='btn btn-lg btn-primary']"

    CHECKOUT_BUTTON = "a[class=checkout-register-btn]"

    FAMILY_NAME_INPUT = "input[name=signUpUser.defaultAddress.familyName]"
    FIRST_NAME_INPUT = "input[name=signUpUser.defaultAddress.firstName]"
    FAMILY_NAME_KANA_INPUT = "input[name=signUpUser.defaultAddress.familyNameKana]"
    FIRST_NAME_KANA_INPUT = "input[name=signUpUser.defaultAddress.firstNameKana]"
    POSTAL_CODE_INPUT = "input[name=signUpUser.defaultAddress.zipCode]"
    ADDRESS_INPUT = "input[name=signUpUser.defaultAddress.address]"
    APARTMENT_INPUT = "input[name=signUpUser.defaultAddress.buildingName]"
    PHONE_NUMBER = "input[name=signUpUser.defaultAddress.tel]"
    GENDER = "input[name=signUpUser.genderShopId]"
    BIRTHDAY_YEAR = "#react-select-3--value"
    BIRTHDAY_MONTH = "#react-select-4--value"
    BIRTHDAY_DAY = "#react-select-5--value"
    EMAIL_INPUT = "input[name=signUpUser.email]"
    PASSWORD = "input[name=signUpUser.password]"

    PAYMENT_METHOD_GMO_CREDIT_CARD = "input#2"
    PAYMENT_METHOD_NP_ATOBARAI = "input#4"

    SUBSC_STORE_PAYMENT_CARD_NUMBER_INPUT = "input[name=paymentMethodShop.creditCard.cardNumber]"
    SUBSC_STORE_PAYMENT_NAME_ON_CARD_INPUT = "input[name=paymentMethodShop.creditCard.holderName]"
    SUBSC_STORE_PAYMENT_EXPIRY_MONTH_INPUT = "#react-select-8--value"
    SUBSC_STORE_PAYMENT_EXPIRY_YEAR_INPUT = "#react-select-9--value"
    SUBSC_STORE_PAYMENT_SECURITY_CODE_INPUT = "input[name=paymentMethodShop.creditCard.securityCode]"

    CHECKOUT_SUBMIT_BUTTON = "button#subsc-to-confirm"

    CONFIRM_PAYMENT_BUTTON = "#subsc-submit-order-top"

    def process
      @log_tab_level += 1
      Log.info "Start process", @log_tab_level

      begin
        product_page
        checkout_page
        checkout_register
        confirm_page
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
        select QUANLITY_INPUT, quantity_value, :quantity
      end

      capture
      click ADD_TO_CART_BUTTON, "Add product to cart"
    end

    def checkout_page
      @log_tab_level += 1
      Log.info "checkout_page", @log_tab_level
      wait_element_load CHECKOUT_BUTTON
      capture
      click CHECKOUT_BUTTON, "Click checkout button"
    end

    def checkout_register
      @log_tab_level += 1
      Log.info "checkout_register", @log_tab_level
      wait_element_load FAMILY_NAME_INPUT
      fill_to_text_input FAMILY_NAME_INPUT, user_name["valueLeft"], "Fill-in family name"
      fill_to_text_input FIRST_NAME_INPUT, user_name["valueRight"], "Fill-in first name"
      fill_to_text_input FAMILY_NAME_KANA_INPUT, user_name_kana["valueLeft"], "Fill-in family name kana"
      fill_to_text_input FIRST_NAME_KANA_INPUT, user_name_kana["valueRight"], "Fill-in first name kana"
      fill_to_text_input POSTAL_CODE_INPUT, @post_code, "Fill-in post code"
      fill_to_text_input ADDRESS_INPUT, @data_address["value_address"], "Fill-in address"
      fill_to_text_input APARTMENT_INPUT, @data_address["value_building_name"], "Fill-in building name"
      fill_to_text_input PHONE_NUMBER, phone_number, "Fill-in user email"
      if sex_value.present?
        click "input[value='#{sex_value}']"
      end
      select BIRTHDAY_YEAR, birth_date["valueYear"], :birthday_year
      select BIRTHDAY_MONTH, birth_date["valueMonth"].to_i.to_s, :birthday_month
      select BIRTHDAY_DAY, birth_date["valueDay"].to_i.to_s, :birthday_day

      fill_to_text_input EMAIL_INPUT, @user_email, "Fill-in email"
      fill_to_text_input PASSWORD, @first_name, "Fill-in password"

      if credit_card_payment.present?
        click PAYMENT_METHOD_GMO_CREDIT_CARD
        fill_to_text_input SUBSC_STORE_PAYMENT_CARD_NUMBER_INPUT, card_data["card_number"], :card_number
        select SUBSC_STORE_PAYMENT_EXPIRY_MONTH_INPUT, card_data["month"].to_i.to_s, :expire_month

        select SUBSC_STORE_PAYMENT_EXPIRY_YEAR_INPUT, card_data["year"], :expire_year

        fill_to_text_input SUBSC_STORE_PAYMENT_NAME_ON_CARD_INPUT, card_data["card_name"], :card_name

        fill_to_text_input SUBSC_STORE_PAYMENT_SECURITY_CODE_INPUT, card_data["cvc"], :cvc
      elsif np_delivery_payment.present?
        click PAYMENT_METHOD_NP_ATOBARAI
      end


      capture
      click CHECKOUT_SUBMIT_BUTTON, "Click checkout submit button"
    end

    def confirm_page
      @log_tab_level += 1
      Log.info "confirm_page", @log_tab_level
      wait_element_load CONFIRM_PAYMENT_BUTTON
      capture
      click CONFIRM_PAYMENT_BUTTON, "Click confirm payment submit button"
    end

    def extract_conversions_data
      @quantity_value = find_response_by_data_input_name("quantity")
      @user_name = JSON.parse find_response_by_data_input_name("user_name")
      @user_name_kana = JSON.parse find_response_by_data_input_name("user_name_kana")
      @data_address = JSON.parse find_response_by_data_input_name("zip_code_address")

      @post_code = if @data_address["post_code"].present?
          @data_address["post_code"].gsub("-", "")
        elsif data_address["value_post_code"].present?
          @data_address["value_post_code"].gsub("-", "")
        else
          "#{@data_address["value_post_code_left"]}#{@data_address["value_post_code_right"]}"
        end

      @phone_number = find_response_by_data_input_name("phone_number")
      @sex_value = find_response_by_data_input_name("sex")
      @birth_date = JSON.parse find_response_by_data_input_name("birth_date")
      @user_email = find_response_by_data_input_name("user_email")
      encrypted_password_value = find_response_by_data_input_name("user_password")
      @password_value = JWT.decode(encrypted_password_value, SECRET_KEY)[0]["data"]
      @delivery_frequency = find_response_by_data_input_name("delivery_frequency")
      @is_regular_order = @scenario.is_use_only_regular_order || find_response_by_data_input_name("is_regular_order")
      @delivery_method = find_response_by_data_input_name("delivery_method")
      @delivery_date = find_response_by_data_input_name("delivery_date")
      @delivery_time = find_response_by_data_input_name("delivery_time")
      @credit_card_payment = find_response_by_data_input_name("credit_card_payment")
      @card_data = JSON.parse(JWT.decode(@credit_card_payment, SECRET_KEY)[0]["data"]) if @credit_card_payment.present?
      @np_delivery_payment = find_response_by_data_input_name("np_delivery_payment")
    end
  end
end
