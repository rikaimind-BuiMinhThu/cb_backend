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
      :post_code, :phone_number, :sex_value, :birth_date, :user_email, :password_value

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

    def start_tor
      Log.info "Start tor process", @log_tab_level
      @log_tab_level += 1
      system("service tor start")
      Log.info "Started tor", @log_tab_level
      sleep_by_seconds 10
      @log_tab_level -= 1
    end

    def quit_tor
      @log_tab_level += 1
      process_ids = `pgrep tor`.split("\n")

      if process_ids.present?
        system("kill -9 #{process_ids.join(" ")}")
        Log.info "Killed tor process #{process_ids.join(" ")}", @log_tab_level
      end

      @log_tab_level -= 1
    end

    def init_selenium_driver
      @log_tab_level += 1

      start_tor

      Selenium::WebDriver.logger.output = File.join("#{Rails.root}/log", "selenium.log")
      Selenium::WebDriver.logger.level = :debug
      Log.info "Init selenium driver for chrome", @log_tab_level
      tor_proxy = "127.0.0.1:9050"
      options = Selenium::WebDriver::Chrome::Options.new(
        args: [
          "--lang=ja",
          "--incognito",
          "--headless",
          "--no-sandbox",
          "--disable-gpu",
          "--disable-dev-shm-usage",
          "--proxy-server=socks5://#{tor_proxy}",
          "--user-agent=#{user_agents.sample}",
        ],
      )

      @driver = Selenium::WebDriver.for(:chrome, options: options)
      Log.info @driver.execute_script("return navigator.userAgent"), @log_tab_level
      @driver.manage.timeouts.implicit_wait = 300
      @driver.manage.delete_all_cookies
      # options = Selenium::WebDriver::Firefox::Options.new(args: [
      #   '--test-type',
      #   '--ignore-certificate-errors',
      #   "--disable-extensions",
      #   "disable-infobars",
      #   "--incognito",
      #   "--headless",
      #   "--no-sandbox",
      #   "--disable-gpu",
      #   "--disable-dev-shm-usage",
      # ])
      # @driver = Selenium::WebDriver.for(:firefox, options: options)
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
      @log_tab_level += 1
      Log.info "entry_login_page", @log_tab_level
      Log.info "Current URL: #{@driver.current_url}", @log_tab_level + 1

      wait_element_load "#shipping_address_family_name"

      fill_to_text_input "input#shipping_address_family_name", user_name["valueLeft"], "Shipping address Family name"
      sleep_by_seconds 1
      fill_to_text_input "input#shipping_address_first_name", user_name["valueRight"], "Shipping address First name"
      sleep_by_seconds 1
      fill_to_text_input "input#shipping_address_family_name_kana", user_name_kana["valueLeft"], "Shipping address First name Kana"
      sleep_by_seconds 1
      fill_to_text_input "input#shipping_address_first_name_kana", user_name_kana["valueRight"], "Shipping address Family name Kana"
      sleep_by_seconds 1

      fill_to_text_input "input#shipping_address_zip", post_code, "Post code"
      sleep_by_seconds 1

      click "#hide_display_shipping_address", "Search by post_code"

      sleep_by_seconds 5
      fill_to_text_input "[name='shipping_address[address]']", data_address["value_address"], "Shipping Address address"
      sleep_by_seconds 1

      fill_to_text_input "[name='shipping_address[building]']", data_address["value_building_name"], "Shipping Address building"
      sleep_by_seconds 1

      fill_to_text_input "input#shipping_address_tel", phone_number, "Shipping Address Tel"
      sleep_by_seconds 1

      if sex_value.present?
        select_radio_btn "sex_#{sex_value}", sex_value, "Sex"
        sleep_by_seconds 1
      end

      select "#user_birthday_1i", birth_date["valueYear"], :birthday_year
      sleep_by_seconds 1
      select "#user_birthday_2i", birth_date["valueMonth"].to_i.to_s, :birthday_month
      sleep_by_seconds 1
      select "#user_birthday_3i", birth_date["valueDay"].to_i.to_s, :birthday_day
      sleep_by_seconds 1

      fill_to_text_input "#user_email", user_email, "User email"
      sleep_by_seconds 1

      if tamago_repeat_config.email_confirm_required?
        fill_to_text_input "#user_email_confirmation", user_email, "User email"
        sleep_by_seconds 1
      end

      fill_to_text_input "#user_password", password_value, "Password"
      sleep_by_seconds 1
      fill_to_text_input "#user_password_confirmation", password_value, "Password confirmation"
      sleep_by_seconds 1

      click "input#hide_display2", pointer_action: false

      verify_recaptcha

      fill_to_text_input "#user_password", password_value, "Password"
      sleep_by_seconds 1
      fill_to_text_input "#user_password_confirmation", password_value, "Password confirmation"
      sleep_by_seconds 1

      click "input#hide_display2", pointer_action: false

      wait_page_load "order/select_order_method"
      capture
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
      frame = document.find_element("iframe[src*='https://www.google.com/recaptcha/api2/anchor']")
      src = frame.attribute("src")

      google_key = CGI::parse(src)["k"]&.first
      page_url = @driver.current_url

      token = Captcha::RecaptchaV2.new(google_key, page_url, @log_tab_level).process

      js_script = "document.getElementById('g-recaptcha-response').innerHTML = '#{token}'"
      execute_script js_script

      @log_tab_level -= 1
    end

    def shipping_method_and_payment_method_select_page
      Log.info "\tshipping_method_and_payment_method_select_page"
      switch_to :default_content
      capture
      Log.info "\t\tCurrent URL: #{@driver.current_url}"
      # 定期・頒布会配送頻度
      if @scenario.is_use_only_regular_order || conversations.find_by_data_input_name("is_regular_order")&.value
        Log.info "\t\tfrequency_select = @driver.find_elements(id: order1_periodically_term_id)"
        frequency_selectors = @driver.find_elements(id: "order1_periodically_term_id")
        if frequency_selectors.present?
          frequency_selector = frequency_selectors.first
          frequency_value = conversations.find_by_data_input_name("delivery_frequency")&.value

          Log.info "\t\tchoose_frequence = Selenium::WebDriver::Support::Select.new(frequency_selector)"
          choose_frequence = Selenium::WebDriver::Support::Select.new(frequency_selector)
          capture

          Log.info "\t\tchoose_frequence.select_by(:value, frequency_value.to_s)"
          choose_frequence.select_by(:value, frequency_value.to_s)
          capture
        end
      end

      # 配送方法
      Log.info "\t\tselect_delivery_method = @driver.find_element(id: order_delivery_classification_id)"
      select_delivery_method = @driver.find_element(id: "order_delivery_classification_id")
      Log.info "\t\tchoose_select_delivery_method = Selenium::WebDriver::Support::Select.new(select_delivery_method)"
      choose_select_delivery_method = Selenium::WebDriver::Support::Select.new(select_delivery_method)
      capture

      select_delivery_method_value = conversations.find_by_data_input_name("delivery_method").value
      Log.info "\t\tchoose_select_delivery_method.select_by(:value, #{select_delivery_method_value.to_s})"
      choose_select_delivery_method.select_by(:value, select_delivery_method_value.to_s)

      # お届け希望日
      # TODO

      # 時間帯指定
      delivery_time_value = conversations.find_by_data_input_name("delivery_time").value
      Log.info "\t\tdelivery_time_select = @driver.find_element(id: order_expected_arrival_time_zone)"
      delivery_time_select = @driver.find_element(id: "order_expected_arrival_time_zone")
      Log.info "\t\tchoose_delivery_time = Selenium::WebDriver::Support::Select.new(delivery_time_select)"
      choose_delivery_time = Selenium::WebDriver::Support::Select.new(delivery_time_select)
      choose_delivery_time.select_by(:value, delivery_time_value.to_s)

      if conversations.find_by_data_input_name("credit_card_payment").present?
        Log.info "\t\t@driver.find_element(id: \"order_payment_method_id_2\").click()"
        @driver.find_element(id: "order_payment_method_id_2").click()
        Log.info "\t\t@driver.find_element(css: \"input#hide_display\").click()"
        @driver.find_element(css: "input#hide_display").click()
        credit_card_page
      else
        Log.info "\t\t@driver.find_element(id: \"order_payment_method_id_3\").click()"
        @driver.find_element(id: "order_payment_method_id_3").click()
        Log.info "\t\t@driver.find_element(css: \"input#hide_display\").click()"
        @driver.find_element(css: "input#hide_display").click()
      end
    end

    def credit_card_page
      Log.info "\tcredit_card_page"
      Log.info "\t\tdriver.switch_to.default_content()"
      @driver.switch_to.default_content()
      recaptcha_page
      data_card = conversations.find_by_data_input_name("credit_card_payment").value
      data_card = JSON.parse(JWT.decode(data_card, SECRET_KEY)[0]["data"])
      Log.info "\t\tcard_number = @driver.find_element(id: \"new_credit_card_number\")"
      card_number = @driver.find_element(id: "new_credit_card_number")
      Log.info "\t\tcard_number.send_keys(data_card['card_number'])"
      card_number.send_keys(data_card["card_number"])
      Log.info "\t\tcard_name = @driver.find_element(id: \"new_credit_card_name\")"
      card_name = @driver.find_element(id: "new_credit_card_name")
      Log.info "\t\tcard_name.send_keys(data_card['card_name'])"
      card_name.send_keys(data_card["card_name"])
      Log.info "\t\tselect_month = @driver.find_element(id: \"new_credit_effective_date_2i\")"
      select_month = @driver.find_element(id: "new_credit_effective_date_2i")
      choose_select_month = Selenium::WebDriver::Support::Select.new(select_month)
      Log.info "\t\tchoose_select_month.select_by(:value, #{data_card["month"]})"
      choose_select_month.select_by(:value, data_card["month"].to_i.to_s)

      Log.info "\t\tselect_year = @driver.find_element(id: \"new_credit_effective_date_1i\")"
      select_year = @driver.find_element(id: "new_credit_effective_date_1i")
      choose_select_year = Selenium::WebDriver::Support::Select.new(select_year)
      Log.info "\t\tchoose_select_month.select_by(:value, #{data_card["year"]})"
      choose_select_year.select_by(:value, data_card["year"])

      Log.info "\t\tsecurity_code = @driver.find_element(id: \"new_credit_security_code\")"
      security_code = @driver.find_element(id: "new_credit_security_code")
      Log.info "\t\tsecurity_code.send_keys(#{data_card["cvc"]})"
      security_code.send_keys(data_card["cvc"])

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

        Log.info "\t\t@driver.find_element(id: #{installment_payment_radio_btn_id}).click()"
        @driver.find_element(id: installment_payment_radio_btn_id).click()
      end

      Log.info "\t\t@driver.find_element(css: \"input#hide_display\").click()"
      @driver.find_element(css: "input#hide_display").click()
    end

    def confirm_page
      Log.info "\tconfirm_page"
      Log.info "\t\tdriver.switch_to.default_content()"
      @driver.switch_to.default_content()
      Log.info "\t\tsleep 5"
      sleep(5)
      Log.info "\t\t@driver.find_element(css: \"input#hide_display1\").click()"
      @driver.find_element(css: "input#hide_display1").click()
    end

    def quit
      @log_tab_level += 1
      Log.info "driver.quit"
      @status = true
      @driver.quit
      quit_tor
      @log_tab_level -= 1
    end

    def capture(is_capture = true)
      sleep 2

      @log_tab_level += 1
      begin
        if is_capture
          if is_error
            Log.info "#{@step}: capture", @log_tab_level
            @driver.save_screenshot("#{@screenshot_path}/#{@scenario.id}_#{@user_input_id}_#{@step}.png")
          else
            prev_frame = @current_frame
            switch_to :default_content
            Log.info "#{@step}: capture", @log_tab_level
            @driver.save_screenshot("#{@screenshot_path}/#{@scenario.id}_#{@user_input_id}_#{@step}.png")
            switch_to_frame prev_frame
          end
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
      js_script = "document.getElementById('#{css_selector}').checked = true"
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
