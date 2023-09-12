require "selenium-webdriver"
require File.dirname(__FILE__) + "/../log"
include Selenium::WebDriver::Keys

module SeleniumServices
  class EcForce < Base
    CLIENT_KEY = Settings::captcha.client_key
    CAPSOLVER_API_CREATE_TASK = 'https://api.capsolver.com/createTask'
    CAPSOLVER_API_GET_TASK_RESULT = 'https://api.capsolver.com/getTaskResult'
    QUANLITY_INPUT = "input#input-quantity"
    ADD_TO_CART_BUTTON = "button#btn-add"

    CHECKOUT_BUTTON = "a.c-cart_submit__block__link"

    FIRST_NAME_INPUT = "input#order_billing_address_attributes_name01"
    # FIRST_NAME_INPUT = "input#order_billing_address_attributes_name02"
    LAST_NAME_INPUT = "input#order_billing_address_attributes_name02"
    FIRST_NAME_KANA_INPUT = "input#order_billing_address_attributes_kana01"
    # FIRST_NAME_KANA_INPUT = "input#order_billing_address_attributes_kana02"
    LAST_NAME_KANA_INPUT = "input#order_billing_address_attributes_kana02"
    # POSTAL_CODE_INPUT = "input#order_billing_address_attributes_zip01"
    POSTAL_CODE_INPUT_LEFT = "input#order_billing_address_attributes_zip01"
    POSTAL_CODE_INPUT_RIGHT = "input#order_billing_address_attributes_zip02"
    ADDRESS_INPUT = "input#order_billing_address_attributes_addr02"
    EMAIL_INPUT = "input#email"
    LOGIN_EMAIL="input#customer_email"
    LOGIN_EMAIL2="input[name='customer[email]']"
    LOGIN_PASSWORD="input[name='customer[email]']"
    LOGIN_PASSWORD2="input[name='customer[password]']"
    LOGIN_BUTTON="button.c-cart_submit__block__submit"
    LOGIN_BUTTON2="input.btn.btn-sm.btn-default[type=submit][value=ログイン]"
    
    # EMAIL_CONFIRM_INPUT = "input#form-validation-field-4"
    EMAIL_CONFIRM_INPUT = "input[name='order[email_confirmation]']"
    # PHONE_NUMBER_INPUT = "input#form-validation-field-0"
    PHONE_NUMBER_INPUT = "input[name='order[billing_address_attributes][tel01]']"
    PASSWORD_INPUT = "input[name='order[customer_attributes][password]']"
    SELECT_ADDRESS = "select[name='order[shipping_address_id]']"
    SEND_MESSAGE = "textarea[name='order[remark]']"
    COUPON_CODE = "input[name='order[coupon_code]']"
    
    PAYMENT_METHOD = "select#payment_method_id"
    SELECT_PAYMENT_SCHEDULE = "select#select_payment_schedule"
    SELECT_PAYMENT_SCHEDULE_TIME="select#select_scheduled_delivery_time"
    SELECT_PAYMENT_SCHEDULE_DATE="select#select_scheduled_to_be_delivered_at"

    CHECKBOX_ODER = "input#order_free_columns_0_0_13_22"
    CHECKBOX_AGREE_ORDER = "input#agree"

    SELECT_PAYMENT_ID = "select#card-id"
    
    NEXT_CONFIRM_CONTENT = "input#submit"

    CITY_INPUT = "input[name=city]"
    APARTMENT_INPUT = "input[name=address2]"
    CHECKOUT_SUBMIT_BUTTON = "button[type=submit]"

    PAYMENT_SUBMIT_BUTTON = "button.pull-right"
    PAYMENT_SUBMIT_BUTTON2 = "button.p-checkout_confirm__inner__list__block__submit"
    PAYMENT_SUBMIT_BUTTON3 = "button.pull-right"

    EC_FORCE_PAYMENT_CARD_NUMBER_INPUT = "input[name='order[payment_attributes][source_attributes][number]']"
    EC_FORCE_PAYMENT_NAME_ON_CARD_INPUT = "input#input-cc-name"
    EC_FORCE_PAYMENT_EXPIRY_MONTH_INPUT = "select#input-cc-month"
    EC_FORCE_PAYMENT_EXPIRY_YEAR_INPUT = "select#input-cc-year"
    AMAZON_CAPTCHA_VERIFY_BUTTON = "button#amzn-captcha-verify-button"

    # EC_FORCE_PAYMENT_SECURITY_CODE_INPUT = "input[name=paymentMethodShop.creditCard.securityCode]"


    PAY_NOW_BUTTON = "button[type=submit]"

    CHECKBOX_30_INPUT = "input[name='checklist_30']"
    CHECKBOX_35_INPUT = "input[name='checklist_35']"

    def process
      @log_tab_level += 1
      Log.info "Start process", @log_tab_level

      begin
        product_page
        if @has_account == "0"
          checkout_page
          entry_checkout_information
        else
          checkout_page_regist
          bypass_captcha
          entry_checkout_information_regist
        end
        bypass_captcha
        confirm_page
        quit
        @selenium_result.update! result: :done, end_time: DateTime.now, last_step_no: @step
      rescue => e
        Log.error e.message
        Log.error e.backtrace.join("\n\t")
        @is_error = true

        capture false

        quit
        @selenium_result.update! result: :error, end_time: DateTime.now, last_step_no: @step
      end
    end


    private
   
    def product_page
      @log_tab_level += 1
      Log.info "product_page", @log_tab_level
      navigate @scenario.landing_page_product_url
      wait_element_load QUANLITY_INPUT
      if @quantity_value.present?
          fill_to_text_input QUANLITY_INPUT, @quantity_value, "Fill-in quantity", true
      end
      capture false
      click ADD_TO_CART_BUTTON, "Add product to cart"
      # wait_element_load QUANLITY_SELECT
      # if @quantity_value.present?
      #   select QUANLITY_SELECT, @quantity_value.to_s, :quantity

      #   capture false
      #   click ADD_TO_CART_BUTTON, "Add product to cart"
      # end
   
    end


    # def checkout_page
    #   @log_tab_level += 1
    #   Log.info "checkout_page", @log_tab_level
    #   wait_element_load CHECKOUT_BUTTON
    #   capture
    #   click CHECKOUT_BUTTON, "Click checkout button"
    # end


    def checkout_page
      @log_tab_level += 1
      Log.info "checkout_page", @log_tab_level
      # wait_element_load CHECKOUT_BUTTON
      # capture
      # click CHECKOUT_BUTTON, "Click checkout button"
      # wait_element_load driver.find_element(:css, "a[href*='shop/order/new?register_as_member=0']")
      @driver.find_element(:css, "a[href*='/shop/order/new?register_as_member=0']").click()
    end

    def entry_checkout_information
      @log_tab_level += 1
      Log.info "entry_checkout_information", @log_tab_level
      wait_element_load FIRST_NAME_INPUT
      fill_to_text_input FIRST_NAME_INPUT, @first_name, "Fill-in first name"
      # fill_to_text_input LAST_NAME_INPUT, @last_name, "Fill-in last name"
      fill_to_text_input FIRST_NAME_KANA_INPUT, @first_name_kana, "Fill-in_first_name_kana"
      # fill_to_text_input LAST_NAME_KANA_INPUT, @last_name_kana, "Fill-in_last_name_kana"
      # fill_to_text_input POSTAL_CODE_INPUT, @data_address["value_post_code_left"] + @data_address["value_post_code_right"], "Fill-in postal code"
      fill_to_text_input POSTAL_CODE_INPUT_LEFT, @data_address["value_post_code_left"], "Fill-in postal code"
      fill_to_text_input POSTAL_CODE_INPUT_RIGHT, @data_address["value_post_code_right"], "Fill-in postal code"
      fill_to_text_input ADDRESS_INPUT, @data_address["value_address"] + @data_address["value_building_name"], "Fill-in address"
      fill_to_text_input PHONE_NUMBER_INPUT, @phone_number, "Fill-in phonenumber"
      fill_to_text_input EMAIL_INPUT, @user_email, "Fill-in user email"
      fill_to_text_input EMAIL_CONFIRM_INPUT, @user_email, "Fill-in user email"
      # fill_to_text_input PASSWORD_INPUT, password_value, "Fill-in user email"
      
      # select SELECT_ADDRESS, "same", :select_address
      
      # fill_to_text_input COUPON_CODE, @coupons_code, "Fill-in user email"
      if @coupons_code.present?
        click COUPON_CODE
        fill_to_text_input COUPON_CODE, @coupons_code, "Fill-in coupon code"
      end

      if @np_delivery_payment.present?
        select PAYMENT_METHOD, '9', :payment_method
      elsif @credit_card_payment.present?
        select PAYMENT_METHOD, "1", :payment_method

        fill_to_text_input EC_FORCE_PAYMENT_CARD_NUMBER_INPUT, card_data["card_number"], :card_number
        select EC_FORCE_PAYMENT_EXPIRY_MONTH_INPUT, card_data["month"].to_i.to_s, :expire_month

        select EC_FORCE_PAYMENT_EXPIRY_YEAR_INPUT, card_data["year"][-2,2], :expire_year

        fill_to_text_input EC_FORCE_PAYMENT_NAME_ON_CARD_INPUT, card_data["card_holder"], :card_name

        # fill_to_text_input SUBSC_STORE_PAYMENT_SECURITY_CODE_INPUT, card_data["cvc"], :cvc
      end
      checkbox_30 = @driver.find_element css: CHECKBOX_30_INPUT
      @driver.execute_script "arguments[0].click();", checkbox_30
      checkbox_35 = @driver.find_element css: CHECKBOX_35_INPUT
      @driver.execute_script "arguments[0].click();", checkbox_35
      # select SELECT_PAYMENT_SCHEDULE, "day_of_week", :select_address
      # select SELECT_PAYMENT_SCHEDULE_DATE, (Time.now + @delivery_date.to_i.days).strftime("%Y-%-m-%-d").to_s, :delivery_date
      # select SELECT_PAYMENT_SCHEDULE_TIME, @delivery_time, :delivery_time
      # fill_to_text_input SEND_MESSAGE, @sent_message, :send_message
      # select_radio_btn CHECKBOX_ODER, 1, "check oder"

      click NEXT_CONFIRM_CONTENT, "next to page confirm"
      # select COUNTRY_SELECT, @country, "", "Select country name"
      # fill_to_text_input POSTAL_CODE_INPUT, @post_code, "Fill-in post code"
      # fill_to_text_input CITY_INPUT, @data_address["value_municipality"], "Fill-in city name"
      # fill_to_text_input ADDRESS_INPUT, @data_address["value_address"], "Fill-in address"
      # fill_to_text_input APARTMENT_INPUT, @data_address["value_building_name"], "Fill-in building name"
      # click CHECKOUT_SUBMIT_BUTTON, "Click checkout submit button"
    end

   
    def checkout_page_regist
      @log_tab_level += 1
      Log.info "checkout_page", @log_tab_level
      wait_element_load LOGIN_EMAIL2
      fill_to_text_input LOGIN_EMAIL2, @user_email, "fill email_address"
      fill_to_text_input LOGIN_PASSWORD2, password_value, "fill pass"

      click LOGIN_BUTTON, "click login button"
      # capture
      # click CHECKOUT_BUTTON, "Click checkout button"
      # wait_element_load driver.find_element(:css, "a[href*='shop/order/new?register_as_member=0']")
      # driver.find_element(:css, "a[href*='/shop/order/new?register_as_member=0']").click()
    end


    def entry_checkout_information_regist
      @log_tab_level += 1
      Log.info "entry_checkout_information", @log_tab_level
      wait_element_load FIRST_NAME_INPUT
      element = driver.find_element(:id, 'order_billing_address_attributes_name01')
      sleep(3)
      element.clear
      element = driver.find_element(:id, 'order_billing_address_attributes_name02')
      sleep(3)
      element.clear
      element = driver.find_element(:id, 'order_billing_address_attributes_kana01')
      sleep(3)
      element.clear
      element = driver.find_element(:id, 'order_billing_address_attributes_kana02')
      sleep(3)
      element.clear
      fill_to_text_input FIRST_NAME_INPUT, @first_name, "Fill-in first name"
      fill_to_text_input LAST_NAME_INPUT, @last_name, "Fill-in last name"
      fill_to_text_input FIRST_NAME_KANA_INPUT, @first_name_kana, "Fill-in_first_name_kana"
      fill_to_text_input LAST_NAME_KANA_INPUT, @last_name_kana, "Fill-in_last_name_kana"
      element = driver.find_element(:id, 'order_billing_address_attributes_zip01')
      sleep(3)
      element.clear
      # fill_to_text_input POSTAL_CODE_INPUT, @data_address["value_post_code_left"] + @data_address["value_post_code_right"], "Fill-in postal code"
      fill_to_text_input POSTAL_CODE_INPUT_LEFT, @data_address["value_post_code_left"], "Fill-in postal code"
      fill_to_text_input POSTAL_CODE_INPUT_RIGHT, @data_address["value_post_code_right"], "Fill-in postal code"
      fill_to_text_input ADDRESS_INPUT, @data_address["value_address"] + @data_address["value_building_name"], "Fill-in address"
      fill_to_text_input PHONE_NUMBER_INPUT, @phone_number, "Fill-in phonenumber"
      if @np_delivery_payment.present?
        select PAYMENT_METHOD, '9', :payment_method
        elsif @credit_card_payment.present?
        select PAYMENT_METHOD, "1", :payment_method
        if SELECT_PAYMENT_ID
          select SELECT_PAYMENT_ID, "0", :add_new_card
          fill_to_text_input EC_FORCE_PAYMENT_CARD_NUMBER_INPUT, card_data["card_number"], :card_number
          select EC_FORCE_PAYMENT_EXPIRY_MONTH_INPUT, card_data["month"].to_i.to_s, :expire_month
  
          select EC_FORCE_PAYMENT_EXPIRY_YEAR_INPUT, card_data["year"][-2,2], :expire_year
  
          fill_to_text_input EC_FORCE_PAYMENT_NAME_ON_CARD_INPUT, card_data["card_holder"], :card_name
        else
        fill_to_text_input EC_FORCE_PAYMENT_CARD_NUMBER_INPUT, card_data["card_number"], :card_number
          select EC_FORCE_PAYMENT_EXPIRY_MONTH_INPUT, card_data["month"].to_i.to_s, :expire_month
  
          select EC_FORCE_PAYMENT_EXPIRY_YEAR_INPUT, card_data["year"][-2,2], :expire_year
  
          fill_to_text_input EC_FORCE_PAYMENT_NAME_ON_CARD_INPUT, card_data["card_holder"], :card_name
  
          # fill_to_text_input SUBSC_STORE_PAYMENT_SECURITY_CODE_INPUT, card_data["cvc"], :cvc
        end
        end
        # select SELECT_PAYMENT_SCHEDULE, "day_of_week", :select_address
        # select SELECT_PAYMENT_SCHEDULE_DATE, (Time.now + @delivery_date.to_i.days).strftime("%Y-%-m-%-d").to_s, :delivery_date
        # select SELECT_PAYMENT_SCHEDULE_TIME, @delivery_time, :delivery_time
      # fill_to_text_input SEND_MESSAGE, @sent_message, :send_message
      select_radio_btn CHECKBOX_AGREE_ORDER, 1, "check oder"

      click NEXT_CONFIRM_CONTENT, "next to page confirm"
      # select COUNTRY_SELECT, @country, "", "Select country name"
      # fill_to_text_input POSTAL_CODE_INPUT, @post_code, "Fill-in post code"
      # fill_to_text_input CITY_INPUT, @data_address["value_municipality"], "Fill-in city name"
      # fill_to_text_input ADDRESS_INPUT, @data_address["value_address"], "Fill-in address"
      # fill_to_text_input APARTMENT_INPUT, @data_address["value_building_name"], "Fill-in building name"
      # click CHECKOUT_SUBMIT_BUTTON, "Click checkout submit button"
    end

  
    def confirm_page
      @log_tab_level += 1
      Log.info "confirm_page", @log_tab_level
      wait_element_load PAYMENT_SUBMIT_BUTTON2
      capture
      click PAYMENT_SUBMIT_BUTTON2, "Click payment submit button"
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
      @first_name = find_response_by_data_input_name("first_name")
      @last_name = find_response_by_data_input_name("last_name")
      @first_name_kana = find_response_by_data_input_name("first_name_kana")
      @last_name_kana = find_response_by_data_input_name("last_name_kana")
      @data_address = JSON.parse find_response_by_data_input_name("zip_code_address")
      @phone_number = find_response_by_data_input_name("phone_number")
      @user_email = find_response_by_data_input_name("user_email")
      @quantity_value = find_response_by_data_input_name("quantity")
      @coupons_code = find_response_by_data_input_name("coupons_code")
      @payment_method = find_response_by_data_input_name("payment_method")
      @credit_card_payment = find_response_by_data_input_name("credit_card_payment")
      @card_data = JSON.parse(JWT.decode(@credit_card_payment, SECRET_KEY)[0]["data"]) if @credit_card_payment.present?
      @np_delivery_payment = find_response_by_data_input_name("np_delivery_payment")
      @has_account = find_response_by_data_input_name("has_account")
      @delivery_time = find_response_by_data_input_name("delivery_time")
      @delivery_date = find_response_by_data_input_name("delivery_date")
      @sent_message = find_response_by_data_input_name("sent_message")
      encrypted_password_value = find_response_by_data_input_name("user_password")
      @password_value = JWT.decode(encrypted_password_value, SECRET_KEY)[0]["data"] if encrypted_password_value.present?
    end

    def bypass_captcha
      @log_tab_level += 1
      Log.info "bypass_captcha", @log_tab_level
      website_url = @scenario.landing_page_product_url

      text = @driver.page_source
      key_match = text.scan(/"key":"([^"]+)"/)
      iv_match = text.scan(/"iv":"([^"]+)"/)
      context_match = text.scan(/"context":"([^"]+)"/)
      challenge_match = text.scan(/<script.*?src="(.*?)".*?><\/script>/)

      if key_match && iv_match && context_match
        awsKey = key_match.flatten.first
        awsIv = iv_match.flatten.first
        awsContext = context_match.flatten.first
        awsChallengeJS = challenge_match.flatten.first
      end

      params_create_task = {
        'clientKey': CLIENT_KEY,
        'task': {
          'type': 'AntiAwsWafTaskProxyless',
          'websiteURL': website_url,
          'awsKey': awsKey,
          'awsIv': awsIv,
          'awsContext': awsContext,
          'awsChallengeJS': awsChallengeJS
        }
      }
      Log.info "call API createTask", @log_tab_level
      request_create_task = HttpManager.new(CAPSOLVER_API_CREATE_TASK, params_create_task)
      response_create_task = request_create_task.post_request
      sleep 5
      taskId = response_create_task["taskId"]

      params_get_task_result = {
        'clientKey': CLIENT_KEY,
        'taskId': taskId
      }

      Log.info "call API getTaskResult", @log_tab_level
      request_get_task_result = HttpManager.new(CAPSOLVER_API_GET_TASK_RESULT, params_get_task_result)
      response_get_task_result = request_get_task_result.post_request
      sleep 5

      if response_get_task_result["status"] == "ready"
        all_cookies = @driver.manage.all_cookies
        target_cookie = all_cookies.find { |cookie| cookie[:name] == 'aws-waf-token' }
        target_cookie[:value] = response_get_task_result["solution"]["cookie"]
        @driver.manage.delete_cookie(target_cookie[:name])
        @driver.manage.add_cookie(target_cookie)
        @driver.navigate.refresh
      end
      capture
    end
  end
end
