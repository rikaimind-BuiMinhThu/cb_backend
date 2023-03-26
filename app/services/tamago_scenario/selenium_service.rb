require "selenium-webdriver"
require File.dirname(__FILE__) + "/../log"

module TamagoScenario
  class SeleniumService
    REGULAR_ORDER_SELECT_QUANTITY_SELECTOR = "#periodically_order_order_qty_0"
    NORMAL_ORDER_SELECT_QUANTITY_SELECTOR = "#order_order_qty_0"
    TIMEOUT = 300

    SECRET_KEY = Rails.application.secrets.secret_refresh_token
    attr_accessor :scenario, :conversations, :driver, :tamago_repeat_config, :status

    attr_accessor :quantity_value, :user_name, :user_name_kana, :data_address,
      :post_code, :phone_number, :sex_value, :birth_date, :user_email, :password_value,
      :delivery_frequency, :is_regular_order, :delivery_method, :delivery_date,
      :credit_card_payment, :card_data

    attr_accessor :is_error

    def initialize(scenario, conversations)
      Log.info "Start selenium service for: \n\tscenario: #{scenario.id}\n\tconversations: #{conversations.map(&:id).inspect}"
      @scenario = scenario
      @conversations = conversations.to_a
      @user_input_id = conversations.first.user_input_id || "sample"
      @tamago_repeat_config = @scenario.tamago_repeat_config
      @status = false
      @screenshot_path = "#{Rails.root}/tmp/selenium"
      @step = 1
      @current_frame = nil
      @log_tab_level = 0
      @is_error = nil

      extract_conversions_data

      init_selenium_driver
    end

    def process
      @log_tab_level += 1
      Log.info "Start process", @log_tab_level

      begin
        cart_page
        entry_login_page
        shipping_method_and_payment_method_select_page
        confirm_page
        quit
      rescue => e
        Log.error e.message
        Log.error e.backtrace.join("\n\t")
        @is_error = true

        capture true

        quit
      end
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

    def cart_page
      @log_tab_level += 1
      Log.info "cart_page", @log_tab_level
      navigate tamago_repeat_config.tamago_landing_page_url
      wait_element_load "input#hide_display"
      capture

      if quantity_value.present?
        quantity_css_selector = if @scenario.is_use_only_regular_order || conversations.find_by_data_input_name("is_regular_order")&.value
            REGULAR_ORDER_SELECT_QUANTITY_SELECTOR
          else
            NORMAL_ORDER_SELECT_QUANTITY_SELECTOR
          end

        select quantity_css_selector, quantity_value, :quantity
      end

      click "input#hide_display", "Cart page submit button"
    end

    def entry_login_page
      Log.info "entry_login_page", @log_tab_level
      @log_tab_level += 1
      Log.info "Current URL: #{@driver.current_url}", @log_tab_level

      wait_element_load "#new_signup #shipping_address_family_name"

      # sleep_by_seconds 1

      fill_to_text_input "#new_signup input#shipping_address_family_name", user_name["valueLeft"], "Shipping address Family name"
      # sleep_by_seconds 1
      fill_to_text_input "#new_signup input#shipping_address_first_name", user_name["valueRight"], "Shipping address First name"
      # sleep_by_seconds 1
      fill_to_text_input "#new_signup input#shipping_address_family_name_kana", user_name_kana["valueLeft"], "Shipping address First name Kana"
      # sleep_by_seconds 1
      fill_to_text_input "#new_signup input#shipping_address_first_name_kana", user_name_kana["valueRight"], "Shipping address Family name Kana"
      # sleep_by_seconds 1

      fill_to_text_input "#new_signup input#shipping_address_zip", post_code, "Post code"
      # sleep_by_seconds 1

      click "#new_signup #hide_display_shipping_address a", "Search by post_code"

      sleep_by_seconds 1
      fill_to_text_input "#new_signup [name='shipping_address[address]']", data_address["value_address"], "Shipping Address address"
      # sleep_by_seconds 1

      fill_to_text_input "#new_signup [name='shipping_address[building]']", data_address["value_building_name"], "Shipping Address building"
      # sleep_by_seconds 1

      fill_to_text_input "#new_signup input#shipping_address_tel", phone_number, "Shipping Address Tel"
      # sleep_by_seconds 1

      if sex_value.present?
        select_radio_btn "#new_signup #sex_#{sex_value}", sex_value, "Sex"
        # sleep_by_seconds 1
      end

      select "#new_signup #user_birthday_1i", birth_date["valueYear"], :birthday_year
      # sleep_by_seconds 1
      select "#new_signup #user_birthday_2i", birth_date["valueMonth"].to_i.to_s, :birthday_month
      # sleep_by_seconds 1
      select "#new_signup #user_birthday_3i", birth_date["valueDay"].to_i.to_s, :birthday_day
      # sleep_by_seconds 1

      fill_to_text_input "#new_signup #user_email", user_email, "User email"
      # sleep_by_seconds 1

      unless tamago_repeat_config.email_confirm_none?
        fill_to_text_input "#new_signup #user_email_confirmation", user_email, "User email"
        # sleep_by_seconds 1
      end

      try_count = 1
      while try_count < 10
        Log.info "Try #{try_count} times", @log_tab_level
        sleep_by_seconds 5
        break unless @driver.current_url.include?("order/entry_login")

        verify_recaptcha
        fill_to_text_input "#new_signup #user_password", password_value, "Password"
        # sleep_by_seconds 1
        fill_to_text_input "#new_signup #user_password_confirmation", password_value, "Password confirmation"
        # sleep_by_seconds 1

        click "input#hide_display2", pointer_action: false
        try_count += 1
      end

      if try_count == 10
        raise "Can not pass captcha"
      end

      # logs = @driver.manage.logs.get(:browser)
      # Log.info logs.inspect

      wait_page_load "order/select_order_method"
      capture
      @log_tab_level -= 1
    end

    # def recaptcha_page
    #   # return true
    #   # return unless is_displaying_recaptcha?
    #   @log_tab_level += 1
    #   sleep_by_seconds 2

    #   Log.info "recaptcha_page", @log_tab_level
    #   begin
    #     verify_recaptcha
    #   rescue StandardError => e
    #     Log.error "Error: #{e.message}", @log_tab_level
    #     sleep_by_seconds 5
    #     switch_to :default_content
    #     sleep_by_seconds
    #     verify_recaptcha
    #   end
    #   @log_tab_level -= 1
    # end

    def verify_recaptcha
      Log.info "verify_captcha", @log_tab_level
      @log_tab_level += 1
      switch_to :default_content
      frame = @driver.find_element(css: "iframe[src*='https://www.google.com/recaptcha/api2/anchor']")
      src = frame.attribute("src")

      execute_script "window.reset = function() {}; window.execute = function() {};grecaptcha = {ready: function() {}, reset: function(){}, execute: function(){}};"
      execute_script "document.querySelector('#recaptcha').remove();document.querySelector(\"iframe[title*='recaptcha']\").parentElement.remove();"

      capture

      sleep_by_seconds 5

      @driver.action.pointer_down(:left).pointer_up(:left).perform

      google_key = CGI::parse(src)["k"]&.first
      page_url = @driver.current_url

      token = Captcha::RecaptchaV2.new(google_key, page_url, @log_tab_level).process
      Log.info "token: #{token}", @log_tab_level

      js_script = "textarea = document.createElement('textarea');"
      js_script += "textarea.name = 'g-recaptcha-response';"
      js_script += "textarea.innerHTML = '#{token}';"
      js_script += "document.querySelector('#new_signup').append(textarea);"
      execute_script js_script

      @log_tab_level -= 1
    end

    def shipping_method_and_payment_method_select_page
      Log.info "shipping_method_and_payment_method_select_page", @log_tab_level
      @log_tab_level += 1
      switch_to :default_content
      capture
      Log.info "Current URL: #{@driver.current_url}", @log_tab_level
      # 定期・頒布会配送頻度
      if is_regular_order
        select "#order1_periodically_term_id", delivery_frequency, :delivery_frequency
        # sleep_by_seconds 1
      end

      # 配送方法
      select "#order_delivery_classification_id", delivery_method, :delivery_method
      # sleep_by_seconds 1

      # お届け希望日
      # TODO

      # 時間帯指定
      select "#order_expected_arrival_time_zone", delivery_date, :delivery_date
      # sleep_by_seconds 1

      if credit_card_payment.present?
        click "#order_payment_method_id_2"
        # sleep_by_seconds 1
        click "input#hide_display"
        # sleep_by_seconds 1

        credit_card_page
      else
        click "#order_payment_method_id_3"
        # sleep_by_seconds 1
        click "input#hide_display"
      end
    end

    def credit_card_page
      Log.info "credit_card_page", @log_tab_level
      @log_tab_level += 1

      switch_to :default_content
      verify_captcha

      # sleep_by_seconds 1

      fill_to_text_input "#new_credit_card_number", data_card["card_number"], :card_number
      # sleep_by_seconds 1

      fill_to_text_input "#new_credit_card_name", data_card["card_name"], :card_name
      # sleep_by_seconds 1

      select "#new_credit_effective_date_2i", data_card["month"].to_i.to_s, :expire_month
      # sleep_by_seconds 1

      select "#new_credit_effective_date_1i", data_card["year"], :expire_year
      # sleep_by_seconds 1

      fill_to_text_input "#new_credit_security_code", data_card["cvc"], :cvc
      # sleep_by_seconds 1

      installment_payment_value = data_card["payment_method"][0]

      if installment_payment_value.present?
        installment_payment_radio_btn_id = case installment_payment_value
          when "jcb"
            "new_credit_card_brand_jcb"
          when "diners"
            "new_credit_card_brand_diners"
          when "amex"
            "new_credit_card_brand_amex"
          when "other"
            "new_credit_card_brand_other"
          end

        click "##{installment_payment_radio_btn_id}", :card_type
        # sleep_by_seconds 1
      end

      click "input#hide_display", :submit

      @log_tab_level -= 1
    end

    def confirm_page
      Log.info "confirm_page", @log_tab_level
      @log_tab_level += 1
      switch_to :default_content
      sleep_by_seconds 5

      click "input#hide_display1", :submit_on_confirm

      @log_tab_level -= 1
    end

    def quit
      Log.info "quit", @log_tab_level
      @log_tab_level += 1
      Log.info "driver.quit", @log_tab_level
      @status = true
      @driver.quit
      @log_tab_level -= 1
    end

    def capture(is_capture = true)
      sleep 2

      @log_tab_level += 1
      begin
        if is_capture
          Log.info "#{@step}: capture", @log_tab_level
          @driver.save_screenshot("#{@screenshot_path}/#{@scenario.id}_#{@user_input_id}_#{@step}.png")
        end
      rescue e
        Log.error "#{@step}: capture failue", @log_tab_level
      end
      @step += 1
      @log_tab_level -= 1
    end

    def execute_script(js_script)
      Log.info "execute_script: #{js_script}", @log_tab_level
      @log_tab_level += 1
      @driver.execute_script(js_script)
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

    def navigate(url)
      @log_tab_level += 1
      Log.info "driver.navigate.to #{url}", @log_tab_level
      @driver.navigate.to url
      @log_tab_level -= 1
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

    def select_radio_btn(css_selector, value, attr_name = "", description = "", pointer_action: true)
      @log_tab_level += 1
      Log.info "Select radio button #{attr_name}: #{description}", @log_tab_level
      js_script = "document.querySelector('#{css_selector}').checked = true"
      Log.info "@driver.execute_script(#{js_script})", @log_tab_level + 1
      @driver.execute_script(js_script)

      capture
      @log_tab_level -= 1
      @driver.action.pointer_down(:left).pointer_up(:left).perform if pointer_action
    end

    def fill_to_text_input(css_selector, value, description = "", pointer_action: true)
      @log_tab_level += 1
      Log.info "Fill to text input #{css_selector}: #{description}", @log_tab_level
      Log.info "input_element = @driver.find_element(css: #{css_selector})", @log_tab_level + 1
      input_element = @driver.find_element(css: css_selector)
      Log.info "input_element.send_keys(#{value})", @log_tab_level + 1
      input_element.send_keys(value)
      capture
      @log_tab_level -= 1
      @driver.action.pointer_down(:left).pointer_up(:left).perform if pointer_action
    end

    def wait_page_load(sub_url)
      @log_tab_level += 1
      wait = Selenium::WebDriver::Wait.new(:timeout => TIMEOUT)
      wait.until { @driver.current_url.include?(sub_url) }
      @log_tab_level -= 1
    end

    def wait_element_load(css_selector)
      @log_tab_level += 1
      wait = Selenium::WebDriver::Wait.new(:timeout => TIMEOUT)
      wait.until { @driver.find_element(css: css_selector).displayed? }
      capture
      @log_tab_level -= 1
    end

    def is_displaying_recaptcha?
      @log_tab_level += 1
      Log.info "Check is_displaying_recaptcha", @log_tab_level
      frames = @driver.find_elements(css: "iframe[title^='recaptcha']")
      Log.info "captcha frames length: #{frames.length}", @log_tab_level
      if frames.empty?
        @log_tab_level -= 1
        return false
      end

      Log.info "@driver.switch_to.frame(frame)", @log_tab_level
      @driver.switch_to.frame(frames.first)

      audio_btn = @driver.find_elements(id: "recaptcha-audio-button")
      switch_to :default_content

      @log_tab_level -= 1
      return audio_btn.present?
    end

    def sleep_by_seconds(seconds = 1)
      @log_tab_level += 1
      Log.info "sleep(#{seconds})", @log_tab_level
      sleep(seconds)
      @log_tab_level -= 1
    end

    def download_file(src)
      uri = URI(src)
      file_data = Net::HTTP.get_response(uri).body
      file_name = SecureRandom.hex(32)

      tmp_folder = File.join(Rails.root, "tmp")

      file = File.join(tmp_folder, "#{file_name}.mp3")
      File.open(file, "w:UTF-8") { |file| file.write(file_data.force_encoding("UTF-8")) }
    end

    def switch_to(css_selector = :default_content)
      @log_tab_level += 1
      if css_selector == :default_content
        Log.info "@driver.switch_to.default_content()", @log_tab_level
        @driver.switch_to.default_content()
        @current_frame = nil
        @log_tab_level -= 1
        return
      end

      Log.info "frame = @driver.find_element(css: #{css_selector})", @log_tab_level
      frame = @driver.find_element(css: css_selector)
      @driver.switch_to.frame(frame)
      @current_frame = frame
      @log_tab_level -= 1
    end

    def switch_to_frame(frame)
      return unless frame.present?

      @log_tab_level += 1
      Log.info "\t\tswitch_to_frame #{frame.inspect}", @log_tab_level
      @driver.switch_to.frame(frame)
      @current_frame = frame
      sleep_by_seconds 2
      @log_tab_level -= 1
    end

    def find_response_by_data_input_name(data_input_name)
      conversations.detect { |c| c.data_input_name == data_input_name }&.value
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
      # @credit_card_payment = find_response_by_data_input_name("credit_card_payment")
      # @card_data = JSON.parse(JWT.decode(@credit_card_payment, SECRET_KEY)[0]["data"])
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
