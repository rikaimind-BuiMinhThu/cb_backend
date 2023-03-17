require 'selenium-webdriver'
require File.dirname(__FILE__) + "/log"

module TamagoScenario
  class SeleniumService
    REGULAR_ORDER_SELECT_QUANTITY_SELECTOR = "#periodically_order_order_qty_0"
    NORMAL_ORDER_SELECT_QUANTITY_SELECTOR = "#order_order_qty_0"

    SECRET_KEY = Rails.application.secrets.secret_refresh_token
    attr_accessor :scenario, :conversations, :driver, :tamago_repeat_config, :status

    def initialize(scenario, conversations)
      Log.info "Start selenium service for: \n\tscenario: #{scenario.inspect}\n\tconversations: #{conversations.inspect}"
      @scenario = scenario
      @conversations = conversations
      @user_input_id = conversations.first.user_input_id
      # proxy = Selenium::WebDriver::Proxy.new( socks: '127.0.0.1:9050',socks_version: 5)
      # caps = Selenium::WebDriver::Remote::Capabilities.chrome(proxy: proxy)
      # @driver = Selenium::WebDriver.for :chrome, capabilities: caps
      Selenium::WebDriver.logger.output = File.join("#{Rails.root}/log", "selenium.log")
      Selenium::WebDriver.logger.level = :debug

      Log.info "Init selenium driver"
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless')
      options.add_argument('--no-sandbox')

      @driver = Selenium::WebDriver.for :chrome, options: options
      # @driver = Selenium::WebDriver.for :chrome
      Log.info "Init OK selenium driver"
      @tamago_repeat_config = @scenario.tamago_repeat_config
      @status = false
      @screenshot_path = "#{Rails.root}/tmp/selenium"
      @step = 1
    end

    def process
      Log.info "Start process"

      begin
        cart_page
        entry_login_page
        shipping_method_and_payment_method_select_page
        confirm_page
        quit
      rescue => e
        Log.error e.message
        Log.error e.backtrace.join("\n\t")

        capture true

        quit
      end
    end

    def cart_page
      Log.info "\tcart_page"
      Log.info "\t\tdriver.navigate.to #{tamago_repeat_config.tamago_landing_page_url}"
      @driver.navigate.to tamago_repeat_config.tamago_landing_page_url
      sleep(5)
      
      quantity = conversations.find_by_data_input_name('quantity').value
      select_quantity = 
        if conversations.find_by_data_input_name('is_regular_order').value
          Log.info "\t\tFor regular_order: driver.find_element(css: \"#{REGULAR_ORDER_SELECT_QUANTITY_SELECTOR}\")"
          @driver.find_element css: REGULAR_ORDER_SELECT_QUANTITY_SELECTOR
        else
          Log.info "\t\tFor normal_order: driver.find_element(css: \"#{NORMAL_ORDER_SELECT_QUANTITY_SELECTOR}\")"
          @driver.find_element css: NORMAL_ORDER_SELECT_QUANTITY_SELECTOR
        end
      Log.info "\t\tchoose_select_quantity = Selenium::WebDriver::Support::Select.new(select_quantity)"
      choose_select_quantity = Selenium::WebDriver::Support::Select.new(select_quantity)
      Log.info "\t\tchoose_select_quantity.select(:value, \"#{quantity}\"))"
      choose_select_quantity.select_by(:value, quantity.to_s)
      capture

      Log.info "\t\tinput = @driver.find_element(css: #{tamago_repeat_config.add_to_cart_button_selector})"
      input = @driver.find_element(css: tamago_repeat_config.add_to_cart_button_selector)
      Log.info "\t\tinput.click"
      input.click()
      capture
    end

    def entry_login_page
      Log.info "\tentry_login_page"
      Log.info "\t\tdriver.switch_to.default_content()"
      @driver.switch_to.default_content()
      # recaptcha_page
      #sleep(5)
      data_name = JSON.parse(conversations.find_by_data_input_name('data_name').value)
      first_data = data_name[0]['text_input']['text']
      second_data = data_name[1]['text_input']['text']

      Log.info "\t\tfamily_name = driver.find_element(id: shipping_address_family_name)"
      family_name = @driver.find_element(id: "shipping_address_family_name")
      Log.info "\t\tfamily_name.send_keys(#{first_data['valueLeft']})"
      family_name.send_keys(first_data['valueLeft'])
      capture

      Log.info "\t\tfirst_name = driver.find_element(id: shipping_address_first_name"
      first_name = @driver.find_element(id: "shipping_address_first_name")
      Log.info "\t\tfirst_name.send_keys(#{first_data['valueRight']})"
      first_name.send_keys(first_data['valueRight'])
      capture

      Log.info "\t\tfamily_name_kana = @driver.find_element(id: shipping_address_family_name_kana)"
      family_name_kana = @driver.find_element(id: "shipping_address_family_name_kana")
      Log.info "\t\tfamily_name_kana.send_keys(#{second_data['valueLeft']})"
      family_name_kana.send_keys(second_data['valueLeft'])
      capture

      Log.info "\t\tfirst_name_kana = @driver.find_element(id: shipping_address_first_name_kana)"
      first_name_kana = @driver.find_element(id: "shipping_address_first_name_kana")
      Log.info "\t\tfirst_name_kana.send_keys(#{second_data['valueRight']})"
      first_name_kana.send_keys(second_data['valueRight'])
      capture

      data_address = JSON.parse(conversations.find_by_data_input_name('zip_code_address').value)
      Log.info "\t\tshipping_address_zip = @driver.find_element(css: input#shipping_address_zip)"
      shipping_address_zip = @driver.find_element(css: "input#shipping_address_zip")
      post_code = data_address['post_code'].present? ? data_address['post_code'] : data_address['value_post_code']
      Log.info "\t\tshipping_address_zip.send_keys(#{post_code.gsub('-', '')})"
      shipping_address_zip.send_keys(post_code.gsub('-', ''))
      capture

      Log.info "\t\t@driver.find_element(id: \"hide_display_shipping_address a\").click()"
      @driver.find_element(id: "hide_display_shipping_address a").click()
      Log.info "\t\tsleep(5)"
      sleep(5)
      Log.info "\t\tshipping_address_address = @driver.find_element(name: \"shipping_address[address]\")"
      shipping_address_address = @driver.find_element(name: "shipping_address[address]")
      Log.info "\t\tshipping_address_address.send_keys(#{data_address['value_address']})"
      shipping_address_address.send_keys(data_address['value_address'])
      Log.info "\t\tsleep(2)"
      sleep(2)
      capture

      Log.info "\t\t@driver.find_element(name: \"shipping_address[building]\")"
      shipping_address_building = @driver.find_element(name: "shipping_address[building]")
      Log.info "\t\tshipping_address_building.send_keys(#{data_address['value_building_name']})"
      shipping_address_building.send_keys(data_address['value_building_name'])
      capture

      Log.info "\t\tdriver.find_element(id: \"shipping_address_tel\")"
      shipping_address_tel = @driver.find_element(id: "shipping_address_tel")
      Log.info "\t\tshipping_address_tel.send_keys(#{conversations.find_by_data_input_name('phone_number').value})"
      shipping_address_tel.send_keys(conversations.find_by_data_input_name('phone_number').value)
      capture

      sex_value = conversations.find_by_data_input_name('sex').value  
      if sex_value == 1
        Log.info "\t\t@driver.find_element(id: \"sex_1\").click()"
        @driver.find_element(id: "sex_1").click()
      elsif sex_value == 2
        Log.info "\t\t@driver.find_element(id: \"sex_2\").click()"
        @driver.find_element(id: "sex_2").click()
      end
      capture
      birth_date = JSON.parse(conversations.find_by_data_input_name('birth_date').value)

      Log.info "\t\tselect_year = @driver.find_element(id: \"user_birthday_1i\")"
      select_year = @driver.find_element(id: "user_birthday_1i")
      choose_select_year = Selenium::WebDriver::Support::Select.new(select_year)
      Log.info "\t\tchoose_select_year.select_by(:value, #{birth_date['valueYear']})"
      choose_select_year.select_by(:value, birth_date['valueYear'])
      capture

      Log.info "\t\tselect_month = @driver.find_element(id: \"user_birthday_2i\")"
      select_month = @driver.find_element(id: "user_birthday_2i")
      choose_select_month = Selenium::WebDriver::Support::Select.new(select_month)
      Log.info "\t\tchoose_select_year.select_by(:value, #{birth_date['valueMonth']})"
      choose_select_month.select_by(:value, birth_date['valueMonth'].to_i.to_s)
      capture

      Log.info "\t\tselect_day = @driver.find_element(id: \"user_birthday_3i\")"
      select_day = @driver.find_element(id: "user_birthday_3i")
      choose_select_day = Selenium::WebDriver::Support::Select.new(select_day)
      Log.info "\t\tchoose_select_year.select_by(:value, #{birth_date['valueDay']})"
      choose_select_day.select_by(:value, birth_date['valueDay'].to_i.to_s)
      capture

      Log.info "\t\tuser_email = @driver.find_element(id: \"user_email\")"
      user_email = @driver.find_element(id: "user_email")
      Log.info "\t\tuser_email.send_keys(conversations.find_by_data_input_name('user_email').value)"
      user_email.send_keys(conversations.find_by_data_input_name('user_email').value)
      capture

      if tamago_repeat_config.email_confirm_required?
        Log.info "\t\tuser_email_confirmation = @driver.find_element(id: \"user_email_confirmation\")"
        user_email_confirmation = @driver.find_element(id: "user_email_confirmation")
        Log.info "\t\tuser_email_confirmation.send_keys(#{conversations.find_by_data_input_name('user_email').value})"
        user_email_confirmation.send_keys(conversations.find_by_data_input_name('user_email').value)
        capture
      end

      encrypted_password_value = conversations.find_by_data_input_name('user_password').value
      password_value = JWT.decode(encrypted_password_value, SECRET_KEY)[0]["data"]

      Log.info "\t\tuser_password = @driver.find_element(id: \"user_password\")"
      user_password = @driver.find_element(id: "user_password")
      Log.info "\t\tuser_password.send_keys(#{password_value})"
      user_password.send_keys(password_value)
      capture

      Log.info "\t\tuser_password_confirmation = @driver.find_element(id: \"user_password_confirmation\")"
      user_password_confirmation = @driver.find_element(id: "user_password_confirmation")
      Log.info "\t\tuser_password_confirmation.send_keys(#{password_value})"
      user_password_confirmation.send_keys(password_value)
      capture

      Log.info "\t\tcreate_user_and_next_btn = @driver.find_element(css: input#hide_display2)"
      create_user_and_next_btn = @driver.find_element(css: "input#hide_display2")

      Log.info "\t\tcreate_user_and_next_btn.click()"
      create_user_and_next_btn.click()

      max_sleep = 60
      sleep_count = 1
      while sleep_count <= max_sleep && !@driver.current_url.include?("order/select_order_method")
        Log.info "\t\tsleep 1"
        sleep 1
        sleep_count += 1
      end
      
      capture
    end

    def recaptcha_page
      frame = @driver.find_element(css: "iframe[title^='recaptcha']")
      #sleep(5)
      @driver.switch_to.frame(frame)
      @driver.find_element(id: "recaptcha-audio-button").click()
      #sleep(5)
      src = @driver.find_element(id: "audio-source").attribute("src")
      uri = URI(src)
      file_data = Net::HTTP.get_response(uri).body
      file_name = SecureRandom.hex(32)
      file = File.join(Rails.root, 'public', "#{file_name}.mp3")
      File.open(file, 'w:UTF-8') {|file| file.write(file_data.force_encoding("UTF-8"))}
      audio = Speech::AudioToText.new(file)
      key = audio.to_text.inspect["captured_json"].first.first
      @driver.find_element(id: "audio-response").send_keys(key.lower())
      @driver.find_element(id: "audio-response").send_keys("\n").perform
    end

    def shipping_method_and_payment_method_select_page
      Log.info "\tshipping_method_and_payment_method_select_page"
      Log.info "\t\tdriver.switch_to.default_content()"
      @driver.switch_to.default_content()
      capture
      Log.info "\t\tCurrent URL: #{@driver.current_url}"
      Log.info "\t\tsleep 20"
      sleep 20
      Log.info "\t\tselect_delivery_method = @driver.find_element(id: order_delivery_classification_id)"
      select_delivery_method = @driver.find_element(id: "order_delivery_classification_id")
      Log.info "\t\tchoose_select_delivery_method = Selenium::WebDriver::Support::Select.new(select_delivery_method)"
      choose_select_delivery_method = Selenium::WebDriver::Support::Select.new(select_delivery_method)
      capture

      select_delivery_method_value = conversations.find_by_data_input_name('delivery_method').value
      Log.info "\t\tchoose_select_delivery_method.select_by(:value, #{select_delivery_method_value.to_s})"
      choose_select_delivery_method.select_by(:value, select_delivery_method_value.to_s)

      if conversations.find_by_data_input_name('credit_card_payment').present?
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
      # recaptcha_page
      data_card = conversations.find_by_data_input_name('credit_card_payment').value
      data_card = JSON.parse(JWT.decode(data_card, SECRET_KEY)[0]["data"])
      Log.info "\t\tcard_number = @driver.find_element(id: \"new_credit_card_number\")"
      card_number = @driver.find_element(id: "new_credit_card_number")
      Log.info "\t\tcard_number.send_keys(data_card['card_number'])"
      card_number.send_keys(data_card['card_number'])
      Log.info "\t\tcard_name = @driver.find_element(id: \"new_credit_card_name\")"
      card_name = @driver.find_element(id: "new_credit_card_name")
      Log.info "\t\tcard_name.send_keys(data_card['card_name'])"
      card_name.send_keys(data_card['card_name'])
      Log.info "\t\tselect_month = @driver.find_element(id: \"new_credit_effective_date_2i\")"
      select_month = @driver.find_element(id: "new_credit_effective_date_2i")
      choose_select_month = Selenium::WebDriver::Support::Select.new(select_month)
      Log.info "\t\tchoose_select_month.select_by(:value, #{data_card['month']})"
      choose_select_month.select_by(:value, data_card['month'].to_i.to_s)

      Log.info "\t\tselect_year = @driver.find_element(id: \"new_credit_effective_date_1i\")"
      select_year = @driver.find_element(id: "new_credit_effective_date_1i")
      choose_select_year = Selenium::WebDriver::Support::Select.new(select_year)
      Log.info "\t\tchoose_select_month.select_by(:value, #{data_card['year']})"
      choose_select_year.select_by(:value, data_card['year'])

      Log.info "\t\tsecurity_code = @driver.find_element(id: \"new_credit_security_code\")"
      security_code = @driver.find_element(id: "new_credit_security_code")
      Log.info "\t\tsecurity_code.send_keys(#{data_card['cvc']})"
      security_code.send_keys(data_card['cvc'])

      installment_payment_value = data_card['payment_method'][0]
      
      if installment_payment_value.present?
        installment_payment_radio_btn_id = case installment_payment_value
          when "jcb" then
            "new_credit_card_brand_jcb"
          when "diners" then
            "new_credit_card_brand_diners"
          when "amex" then
            "new_credit_card_brand_amex"
          when "other" then
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
      Log.info "\t\tdriver.quit"
      @status = true
      @driver.quit
    end

    def capture is_capture = false
      if is_capture
        Log.info "\t\t\t#{@step} capture"
        @driver.save_screenshot("#{@screenshot_path}/#{@scenario.id}_#{@user_input_id}_#{@step}.png")
      end
      @step += 1
    end
  end
end
