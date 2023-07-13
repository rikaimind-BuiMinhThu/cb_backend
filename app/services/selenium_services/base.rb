require "selenium-webdriver"
require File.dirname(__FILE__) + "/../log"

module SeleniumServices
  class Base
    REGULAR_ORDER_SELECT_QUANTITY_SELECTOR = "#periodically_order_order_qty_0"
    NORMAL_ORDER_SELECT_QUANTITY_SELECTOR = "#order_order_qty_0"
    TIMEOUT = 300
    SECRET_KEY = Rails.application.secrets.secret_refresh_token
    attr_accessor :scenario, :conversations, :driver, :tamago_repeat_config, :user_input_id

    attr_accessor :quantity_value, :user_name, :user_name_kana, :data_address,
      :post_code, :phone_number, :sex_value, :birth_date, :user_email, :password_value,
      :delivery_frequency, :is_regular_order, :delivery_method, :delivery_date,
      :credit_card_payment, :card_data, :np_delivery_payment, :delivery_time,
      :last_name, :first_name

    attr_accessor :is_error

    def initialize(scenario, conversations)
      Log.info "Start selenium service for: \n\tscenario: #{scenario.id}\n\tconversations: #{conversations.map(&:id).inspect}"
      @scenario = scenario
      @conversations = conversations.to_a
      @user_input_id = conversations.first.user_input_id || "sample"
      @tamago_repeat_config = @scenario.tamago_repeat_config
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

    def quit
      Log.info "quit", @log_tab_level
      @log_tab_level += 1
      Log.info "driver.quit", @log_tab_level
      @driver.quit
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
      rescue
        Log.error "#{@step}: capture failue", @log_tab_level
      end
      @step += 1
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

    def wait_page_load_complete
      @log_tab_level += 1
      Log.info "wait_page_load_complete", @log_tab_level
      wait = Selenium::WebDriver::Wait.new(:timeout => TIMEOUT)
      wait.until { @driver.execute_script('return document.readyState') == 'complete' }
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
      @conversations.detect { |c| c.data_input_name == data_input_name }&.value
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
