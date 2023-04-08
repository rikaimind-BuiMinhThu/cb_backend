require "selenium-webdriver"
require File.dirname(__FILE__) + "/../log"

module ShopifyScenario
  class SeleniumService
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

    PAY_NOW_BUTTON = "button[type=submit]"

    TIMEOUT = 300

    SECRET_KEY = Rails.application.secrets.secret_refresh_token

    attr_accessor :scenario, :conversations, :driver, :shopify_config

    attr_accessor :quantity_value, :user_name, :data_address,
      :post_code, :phone_number, :user_email, :credit_card_payment, :card_data

    attr_accessor :is_error

    def initialize(scenario, conversations)
      Log.info "Start selenium service for: \n\tscenario: #{scenario.id}\n\tconversations: #{conversations.map(&:id).inspect}"
      @scenario = scenario
      @conversations = conversations.to_a
      @user_input_id = conversations.first.user_input_id || "sample"
      @shopify_config = @scenario.shopify_config
      @screenshot_path = "#{Rails.root}/tmp/selenium"
      @step = 1
      @current_frame = nil
      @log_tab_level = 0
      @is_error = nil
      @selenium_result = ScenarioUserResponseSeleniumResult.create(
        scenario_id: scenario.id,
        chatbot_id: scenario.chatbot_id,
        client_id: scenario.chatbot&.user&.client_id,
        user_input_id: @user_input_id,
        last_step_no: 0,
        last_step_description: "",
        start_time: DateTime.now,
        result: :running,
      )

      extract_conversions_data

      init_selenium_driver
    end

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
      navigate shopify_config.landing_page_product_url
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
      entry_payment_information()
    end

    def entry_payment_information
      @log_tab_level += 1
      Log.info "entry_checkout_information", @log_tab_level
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

    def navigate(url)
      @log_tab_level += 1
      Log.info "driver.navigate.to #{url}", @log_tab_level
      @driver.navigate.to url
      @log_tab_level -= 1
    end

    def wait_element_load(css_selector)
      @log_tab_level += 1
      wait = Selenium::WebDriver::Wait.new(:timeout => TIMEOUT)
      wait.until { @driver.find_element(css: css_selector).displayed? }
      capture
      @log_tab_level -= 1
    end

    def click(css_selector, description = "", pointer_action: true)
      @log_tab_level += 1
      Log.info "Click #{css_selector}: #{description}", @log_tab_level
      js_script = "document.querySelector('#{css_selector}').click()"

      Log.info "@driver.execute_script(#{js_script})", @log_tab_level + 1
      @driver.execute_script js_script
      capture
      @log_tab_level -= 1
      @driver.action.pointer_down(:left).pointer_up(:left).perform if pointer_action
    end

    def select(css_selector, value, attr_name = "undefined attributes", description = "", pointer_action: true)
      @log_tab_level += 1
      Log.info "Select for #{attr_name}: #{description}", @log_tab_level
      Log.info "select_element = @driver.find_element(css: \"#{css_selector}\")", @log_tab_level + 1
      select_element = @driver.find_element css: css_selector

      Log.info "support_select = Selenium::WebDriver::Support::Select.new(select_element)", @log_tab_level + 1
      support_select = Selenium::WebDriver::Support::Select.new(select_element)
      Log.info "support_select.select_by(:value, #{value})", @log_tab_level + 1
      support_select.select_by(:value, value)

      capture
      @log_tab_level -= 1
      @driver.action.pointer_down(:left).pointer_up(:left).perform if pointer_action
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

    def select(css_selector, value, attr_name = "undefined attributes", description = "", pointer_action: true)
      @log_tab_level += 1
      Log.info "Select for #{attr_name}: #{description}", @log_tab_level
      Log.info "select_element = @driver.find_element(css: \"#{css_selector}\")", @log_tab_level + 1
      select_element = @driver.find_element css: css_selector

      Log.info "support_select = Selenium::WebDriver::Support::Select.new(select_element)", @log_tab_level + 1
      support_select = Selenium::WebDriver::Support::Select.new(select_element)
      Log.info "support_select.select_by(:value, #{value})", @log_tab_level + 1
      support_select.select_by(:value, value)

      capture
      @log_tab_level -= 1
      @driver.action.pointer_down(:left).pointer_up(:left).perform if pointer_action
    end

    def quit
      Log.info "quit", @log_tab_level
      @log_tab_level += 1
      Log.info "driver.quit", @log_tab_level
      @driver.quit
      @log_tab_level -= 1
    end

    def delete_last_screenshot_file
      @log_tab_level += 1

      begin
        last_file_path = "#{@screenshot_path}/#{@scenario.id}_#{@user_input_id}_#{@step - 1}.png"
        Log.info "Delele #{last_file_path}", @log_tab_level
      rescue
        Log.error "Can not delete #{last_file_path}", @log_tab_level + 1
      end

      @log_tab_level -= 1
    end

    def capture(is_capture = true)
      sleep 2

      @log_tab_level += 1
      begin
        if is_capture
          delete_last_screenshot_file
          Log.info "#{@step}: capture", @log_tab_level
          @driver.save_screenshot("#{@screenshot_path}/#{@scenario.id}_#{@user_input_id}_#{@step}.png")
        end
      rescue e
        Log.error "#{@step}: capture failue", @log_tab_level
      end
      @step += 1
      @log_tab_level -= 1
    end


    def find_response_by_data_input_name(data_input_name)
      conversations.detect { |c| c.data_input_name == data_input_name }&.value
    end

    def extract_conversions_data
      @quantity_value = find_response_by_data_input_name("quantity")
      @user_email = find_response_by_data_input_name("email")
      @country = find_response_by_data_input_name("country")
      @last_name = find_response_by_data_input_name("last_name")
      @first_name = find_response_by_data_input_name("first_name")
      @data_address = JSON.parse find_response_by_data_input_name("zip_code_address")
      @post_code = @data_address["value_post_code"].gsub("-", "")
      @credit_card_payment = find_response_by_data_input_name("credit_card_payment")
      @card_data = JSON.parse(JWT.decode(@credit_card_payment, SECRET_KEY)[0]["data"]) if @credit_card_payment.present?
    end

    def user_agents
      [
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
        "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1",
        "Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36",
        "Mozilla/5.0 (Linux; Android 8.0.0; SM-G955U Build/R16NW) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.141 Mobile Safari/537.36",
        "Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.162 Mobile Safari/537.36",
        "Mozilla/5.0 (iPad; CPU OS 13_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/87.0.4280.77 Mobile/15E148 Safari/604.1",
        "Mozilla/5.0 (Linux; Android 11.0; Surface Duo) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Mobile Safari/537.36",
        "Mozilla/5.0 (Linux; Android 9.0; SAMSUNG SM-F900U Build/PPR1.180610.011) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Mobile Safari/537.36",
        "Mozilla/5.0 (Linux; Android 8.0.0; SM-G955U Build/R16NW) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.141 Mobile Safari/537.36",
        "Mozilla/5.0 (Linux; Android) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.109 Safari/537.36 CrKey/1.54.248666",
      ]
    end
  end
end
