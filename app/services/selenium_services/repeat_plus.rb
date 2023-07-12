require "selenium-webdriver"
require 'timeout'
require File.dirname(__FILE__) + "/../log"

module SeleniumServices
  class RepeatPlus < Base
    QUANTITY_INPUT = "#ctl00_ContentPlaceHolder1_tbCartAddProductCount"
    VARIATION_INPUT = "#ctl00_ContentPlaceHolder1_ddlVariationSelect"
    ADD_TO_CART_BUTTON = "#ctl00_ContentPlaceHolder1_lbCartAdd"
    CHECKOUT_SUBMIT_BUTTON = ".btmbtn.below .btn-success"
    CHECKOUT_BUTTON = "#ctl00_ContentPlaceHolder1_lbNext"
    BTN_SUCCESS = ".btn-success"
    COUPON_CODE_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl01_tbCouponCode"
    BUTTON_CART = "#HeadCartView a"

    EMAIL_INPUT_LOGIN = "#ctl00_ContentPlaceHolder1_tbLoginIdInMailAddr"
    PASSWORD_INPUT_LOGIN = "#ctl00_ContentPlaceHolder1_tbPassword"
    LOGIN_BUTTON = "#ctl00_ContentPlaceHolder1_lbLogin"
    MESSAGE_ERROR_LOGIN = "#ctl00_ContentPlaceHolder1_dLoginErrorMessage"

    REGISTER_BUTTON = "#ctl00_ContentPlaceHolder1_lbUserEasyRegist"
    EMAIL_REGISTER_INPUT = "#ctl00_ContentPlaceHolder1_tbUserMailAddr"
    EMAIL_REGISTER_CONF_INPUT = "#ctl00_ContentPlaceHolder1_tbUserMailAddrConf"
    PASS_REGISTER_INPUT = "#ctl00_ContentPlaceHolder1_tbUserPassword"
    PASS_REGISTER_CONF_INPUT = "#ctl00_ContentPlaceHolder1_tbUserPasswordConf"
    AGREE_CHECK_BOX = "#ctl00_ContentPlaceHolder1_cbUserAcceptedRegulation"
    REGISTER_SUBMIT_BUTTON = "#ctl00_ContentPlaceHolder1_lbRegister"

    LAST_NAME_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_tbOwnerName1"
    FIRST_NAME_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_tbOwnerName2"
    LAST_NAME_KANA_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_tbOwnerNameKana1"
    FIRST_NAME_KANA_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_tbOwnerNameKana2"
    EMAIL_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_tbOwnerMailAddr"
    EMAIL_CONFIRM_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_tbOwnerMailAddrConf"
    POSTAL_CODE_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_tbOwnerZip"
    PREFECTURE_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_ddlOwnerAddr1"
    MUNICIPALITY_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_tbOwnerAddr2"
    ADDRESS_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_tbOwnerAddr3"
    BUILDING_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_tbOwnerAddr4"
    PHONE_NUMBER_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_tbOwnerTel1"
    BIRTHDATE_YEAR_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_ddlOwnerBirthYear"
    BIRTHDATE_MONTH_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_ddlOwnerBirthMonth"
    BIRTHDATE_DAY_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_ddlOwnerBirthDay"
    SEX_MALE_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_rblOwnerSex_0"
    SEX_FEMALE_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_rblOwnerSex_1"

    PAYMENT_METHOD_LABEL = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_Div1"
    PAYMENT_CREDIT_CARD_LABEL = "label[for=ctl00_ContentPlaceHolder1_rCartList_ctl00_rPayment_ctl00_rbgPayment]"
    PAYMENT_NP_LABEL = "label[for=ctl00_ContentPlaceHolder1_rCartList_ctl00_rPayment_ctl00_rbgPayment]"

    CARD_NUMBER_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_rPayment_ctl00_tbCreditCardNo1"
    EXPIRY_MONTH_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_rPayment_ctl00_ddlCreditExpireMonth"
    EXPIRY_YEAR_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_rPayment_ctl00_ddlCreditExpireYear"
    CREDIT_AUTHOR_NAME = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_rPayment_ctl00_tbCreditAuthorName"
    SECURITY_CODE_INPUT = "#ctl00_ContentPlaceHolder1_rCartList_ctl00_rPayment_ctl00_tbCreditSecurityCode"
    def initialize(scenario, conversations)
      Log.info "Start selenium service for: \n\tscenario: #{scenario.id}\n\tconversations: #{conversations.map(&:id).inspect}"
      @scenario = scenario
      @conversations = conversations.to_a
      @user_input_id = conversations.first.user_input_id || "sample"
      @screenshot_path = "#{Rails.root}/tmp/selenium"
      @step = 1
      @current_frame = nil
      @log_tab_level = 0
      @is_error = nil
      @selenium_result = ScenarioUserResponseSeleniumResult.find_by(user_input_id: @user_input_id)

      extract_conversions_data

      init_selenium_driver
    end

    def init_selenium_driver
      @log_tab_level += 1

      Selenium::WebDriver.logger.output = File.join("#{Rails.root}/log", "selenium.log")
      Selenium::WebDriver.logger.level = :debug
      Log.info "Init selenium driver for chrome", @log_tab_level
      options = Selenium::WebDriver::Chrome::Options.new(
        args: [
          "--lang=ja",
          "--incognito",
          "--headless",
          "--no-sandbox",
          "--disable-gpu",
          "--disable-dev-shm-usage",
          "--window-size=2560,1440",
          "--user-agent=#{user_agents.sample}",
        ],
        )

      @driver = Selenium::WebDriver.for(:chrome, options: options)
      Log.info @driver.execute_script("return navigator.userAgent"), @log_tab_level
      @driver.manage.timeouts.implicit_wait = 300
      @driver.manage.delete_all_cookies

      Log.info "Init OK selenium driver", @log_tab_level
      @log_tab_level -= 1
    end

    def process
      @log_tab_level += 1
      Log.info "Start process", @log_tab_level

      begin
        product_page
        checkout_page
        entry_login_page
        cart_selection
        entry_checkout_information
        payment_method
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

      # pass basic authen
      username = "deel"
      password = "YKb!F7Snh"
      encoded_credentials = "#{username}:#{password}"
      url = @scenario.landing_page_product_url
      navigate url.sub('https://', "https://#{encoded_credentials}@")
      #navigate @scenario.landing_page_product_url
      capture
      wait_element_load ADD_TO_CART_BUTTON

      if !@variation.empty?
        select_element = @driver.find_elements(:id, 'ctl00_ContentPlaceHolder1_ddlVariationSelect')
        if select_element.size > 0
          select_element.each do |element|
            options = element.find_elements(:tag_name, 'option')
            options.each do |option|
              text = option.text
              value = option.attribute('value')
              if (text && @variation && text.strip == @variation.strip)
                select VARIATION_INPUT, value, "", "Select variation"
                break
              end
            end
          end
        end
      end
      fill_to_text_input QUANTITY_INPUT, @quantity_value, "Fill-in quantity", true
      sleep_by_seconds 1
      capture
      click ADD_TO_CART_BUTTON, "Add product to cart"
    end

    def checkout_page
      @log_tab_level += 1
      Log.info "checkout_page", @log_tab_level
      wait_element_load CHECKOUT_SUBMIT_BUTTON
      if @driver.find_elements(:id, 'ctl00_ContentPlaceHolder1_rCartList_ctl01_tbCouponCode').size > 0 && @coupons_code.present?
        fill_to_text_input COUPON_CODE_INPUT, @coupons_code, "Fill-in coupon code"
      end
      capture
      click CHECKOUT_SUBMIT_BUTTON, "Click checkout button"
    end

    def cart_selection
      wait_element_load BTN_SUCCESS
      capture
      if @driver.find_elements(:css, BUTTON_CART).size > 0
        click BUTTON_CART, "Click button cart"
      end

      wait_element_load BTN_SUCCESS
      checkout_page
    end

    def entry_login_page
      Log.info "entry_login_page", @log_tab_level
      @log_tab_level += 1
      Log.info "Current URL: #{@driver.current_url}", @log_tab_level

      wait_element_load LOGIN_BUTTON
      fill_to_text_input EMAIL_INPUT_LOGIN, @user_email, "Fill-in email login"
      fill_to_text_input PASSWORD_INPUT_LOGIN, @password_value, "Fill-in password login"
      capture
      click LOGIN_BUTTON,"Click login button"
      sleep_by_seconds 5

      if @driver.current_url.include?("OrderOwnerDecision.aspx")
        capture
        register_member
      end
    end

    def register_member

      wait_element_load REGISTER_BUTTON
      click REGISTER_BUTTON, "Click button register"
      sleep_by_seconds 1
      wait_element_load EMAIL_REGISTER_INPUT
      fill_to_text_input EMAIL_REGISTER_INPUT, @user_email, "Fill-in email"
      fill_to_text_input EMAIL_REGISTER_CONF_INPUT, @user_email, "Fill-in email confirm"
      fill_to_text_input PASS_REGISTER_INPUT, @password_value, "Fill-in email password"
      fill_to_text_input PASS_REGISTER_CONF_INPUT, @password_value, "Fill-in email password confirm"
      click AGREE_CHECK_BOX, "Click checkbox agree"
      sleep_by_seconds 1
      capture
      click REGISTER_SUBMIT_BUTTON, "Click button submit register"

    end
    def entry_checkout_information
      @log_tab_level += 1
      Log.info "entry_checkout_information", @log_tab_level
      capture

      wait_element_load PHONE_NUMBER_INPUT

      fill_to_text_input LAST_NAME_INPUT, @user_name["valueLeft"], "Shipping address Family name", true
      fill_to_text_input FIRST_NAME_INPUT, @user_name["valueRight"], "Shipping address First name", true

      fill_to_text_input LAST_NAME_KANA_INPUT, @user_name_kana["valueLeft"], "Shipping address Last name Kana", true
      fill_to_text_input FIRST_NAME_KANA_INPUT, @user_name_kana["valueRight"], "Shipping address First name Kana", true

      select BIRTHDATE_YEAR_INPUT, @birth_date["valueYear"], "", "Select year of birth"
      select BIRTHDATE_MONTH_INPUT, @birth_date["valueMonth"].to_i.to_s, "", "Select month of birth"
      select BIRTHDATE_DAY_INPUT, @birth_date["valueDay"].to_i.to_s, "", "Select date of birth"

      if @sex_value == 1
        click SEX_MALE_INPUT, "Click sex male"
      else
        click SEX_FEMALE_INPUT, "Click sex female"
      end

      fill_to_text_input EMAIL_INPUT, @user_email, "Fill-in email", true
      fill_to_text_input EMAIL_CONFIRM_INPUT, @user_email, "Fill-in email confirm", true

      fill_to_text_input POSTAL_CODE_INPUT, @post_code, "Fill-in post code", true
      select PREFECTURE_INPUT, @prefecture_value, "Fill-in prefecture"
      fill_to_text_input MUNICIPALITY_INPUT, @municipality_value, "Fill-in municipality", true
      fill_to_text_input ADDRESS_INPUT, @address_value, "Fill-in address", true
      fill_to_text_input BUILDING_INPUT, @building_name_value, "Fill-in building name", true

      fill_to_text_input PHONE_NUMBER_INPUT, @phone_number, "Fill-in phone number", true

      capture
      click CHECKOUT_SUBMIT_BUTTON, "Click checkout submit button"
    end

    def payment_method
      @log_tab_level += 1
      Log.info "payment_method", @log_tab_level
      wait_element_load(PAYMENT_METHOD_LABEL)
      capture
      if @credit_card_payment.present?
        entry_credit_payment_information
        Log.info "finish", @log_tab_level
        sleep_by_seconds 1
        capture
      elsif @np_delivery_payment.present?
        entry_np_delivery_payment
      end
    end

    def entry_np_delivery_payment
      @log_tab_level += 1
      Log.info "entry_np_delivery_payment", @log_tab_level
      # wait_element_load PAYMENT_NP_LABEL
      # capture
      # click PAYMENT_NP_LABEL, "Click NP option"
    end

    def entry_credit_payment_information
      @log_tab_level += 1
      Log.info "entry_credit_payment_information", @log_tab_level
      wait_element_load PAYMENT_CREDIT_CARD_LABEL
      click PAYMENT_CREDIT_CARD_LABEL, "Click credit card option"
      sleep_by_seconds 1

      wait_element_load CARD_NUMBER_INPUT
      fill_to_text_input CARD_NUMBER_INPUT, @card_data["card_number"], "Fill-in card number"

      wait_element_load EXPIRY_MONTH_INPUT
      fill_to_text_input EXPIRY_MONTH_INPUT, @card_data["month"], "Fill-in expiry month"

      wait_element_load EXPIRY_YEAR_INPUT
      fill_to_text_input EXPIRY_YEAR_INPUT, @card_data["year"].slice(-2, 2), "Fill-in expiry year"

      wait_element_load CREDIT_AUTHOR_NAME
      fill_to_text_input CREDIT_AUTHOR_NAME, @card_data["card_holder"], "Fill-in card holder"

      wait_element_load SECURITY_CODE_INPUT
      fill_to_text_input SECURITY_CODE_INPUT, @card_data["cvc"], "Fill-in cvc"

      wait_element_load CHECKOUT_SUBMIT_BUTTON
      capture
      click CHECKOUT_SUBMIT_BUTTON, "Click payment button"
      sleep_by_seconds 1
      capture
      click CHECKOUT_SUBMIT_BUTTON, "Click payment button confirm"
    end

    def fill_to_text_input(css_selector, value, description = "", clear_input = false, pointer_action: true)
      @log_tab_level += 1
      Log.info "Fill to text input #{css_selector}: #{description}", @log_tab_level
      Log.info "input_element = @driver.find_element(css: #{css_selector})", @log_tab_level + 1
      input_element = @driver.find_element(css: css_selector)
      Log.info "input_element.send_keys(#{value})", @log_tab_level + 1
      if clear_input
        js_script = "document.querySelector('#{css_selector}').value = ''"
        @driver.execute_script(js_script)
      end
      input_element.send_keys(value)
      capture
      @log_tab_level -= 1
      @driver.action.pointer_down(:left).pointer_up(:left).perform if pointer_action
    end

    def extract_conversions_data

      quantity = find_response_by_data_input_name("quantity").to_i
      @quantity_value = quantity.zero? ? 1 : quantity
      text_with_thumbnail_image = find_response_by_data_input_name("text_with_thumbnail_image")
      @variation = ""
      if text_with_thumbnail_image.present?
        text_with_thumbnail_image = JSON.parse text_with_thumbnail_image
        if text_with_thumbnail_image["products"].present?
          initial_selection = text_with_thumbnail_image["initial_selection"]
          filtered_product = text_with_thumbnail_image["products"].find { |product| product["id"] == initial_selection }
          if filtered_product.present?
            @variation = filtered_product["title"]
          end
        end
      end
      @user_email = find_response_by_data_input_name("user_email")
      encrypted_password_value = find_response_by_data_input_name("password")
      @password_value = JWT.decode(encrypted_password_value, SECRET_KEY)[0]["data"]

      @coupons_code = find_response_by_data_input_name("coupons_code")
      @user_name = JSON.parse find_response_by_data_input_name("user_name")
      @user_name_kana = JSON.parse find_response_by_data_input_name("user_name_kana")
      @birth_date = JSON.parse find_response_by_data_input_name("birth_date")
      @sex_value = find_response_by_data_input_name("sex")
      data_address = JSON.parse find_response_by_data_input_name("zip_code_address")
      @post_code = if data_address["post_code"].present?
                     data_address["post_code"].gsub("-", "")
                   elsif data_address["value_post_code"].present?
                     data_address["value_post_code"].gsub("-", "")
                   else
                     "#{data_address["value_post_code_left"]}#{data_address["value_post_code_right"]}"
                   end
      @prefecture_value = data_address["value_prefecture"]
      @municipality_value = data_address["value_municipality"]
      @address_value = data_address["value_address"]
      @building_name_value = data_address["value_building_name"]
      @phone_number = find_response_by_data_input_name("phone_number")
      @credit_card_payment = find_response_by_data_input_name("credit_card_payment")

      @card_data = JSON.parse(JWT.decode(@credit_card_payment, SECRET_KEY)[0]["data"]) if @credit_card_payment.present?

      @np_delivery_payment = find_response_by_data_input_name("np_delivery_payment")

    end

    def user_agents
      [
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246",
        "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36",
        "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0.1",
        "Mozilla/5.0 (X11; CrOS x86_64 8172.45.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.64 Safari/537.36"
      ]
    end
  end
end
