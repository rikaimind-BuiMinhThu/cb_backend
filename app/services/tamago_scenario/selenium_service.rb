require 'selenium-webdriver'
require File.dirname(__FILE__) + "/log"

module TamagoScenario
  class SeleniumService
    SECRET_KEY = Rails.application.secrets.secret_refresh_token
    attr_accessor :scenario, :conversations, :driver, :tamago_repeat_config

    def initialize(scenario, conversations)
      Log.info "Start selenium service for: \n\tscenario: #{scenario.inspect}\n\tconversations: #{conversations.inspect}"
      @scenario = scenario
      @conversations = conversations
      # proxy = Selenium::WebDriver::Proxy.new( socks: '127.0.0.1:9050',socks_version: 5)
      # caps = Selenium::WebDriver::Remote::Capabilities.chrome(proxy: proxy)
      # @driver = Selenium::WebDriver.for :chrome, capabilities: caps
      Selenium::WebDriver.logger.output = File.join("#{Rails.root}/log", "selenium.log")
      Selenium::WebDriver.logger.level = :debug

      Log.info "Init selenium driver"
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless')
      @driver = Selenium::WebDriver.for :chrome, options: options
      # @driver = Selenium::WebDriver.for :chrome
      Log.info "Init OK selenium driver"
      @tamago_repeat_config = @scenario.tamago_repeat_config
    end

    def process
      Log.info "Start process"
      cart_page
      entry_login_page
      payment_page
      confirm_page
      quit
    end

    def cart_page
      Log.info "\tcart_page"
      Log.info "\t\tdriver.navigate.to #{tamago_repeat_config.tamago_landing_page_url}"
      @driver.navigate.to 'https://egg-cart:egg-cart@new-trial03.tamago-cart.com'
      @driver.navigate.to 'https://egg-cart:egg-cart@new-trial03.tamago-cart.com/plus/admin/menu/enter_login'

      login_code = @driver.find_element(id: 'admin_user_login_code')
      login_code.send_keys('GuUfHQKYilYk')
      login_code = @driver.find_element(id: 'admin_user_hashed_password')
      login_code.send_keys('yzb0Je1IKw5O')
      @driver.find_element(name: 'commit').click()
      sleep(5)
      @driver.navigate.to tamago_repeat_config.tamago_landing_page_url
      Log.info "\t\tdriver.find_element(css: \"#{tamago_repeat_config.add_to_cart_button_selector}\")"
      if conversations.find_by_data_input_name('is_regular_order').value
        @driver.find_element(xpath: '//a[@href="/shop/add_to_cart/?item_qty_1[qty]=1&item_id_1=order&return_url=https://new-trial03.tamago-cart.com"]').click()
      else
        @driver.find_element(xpath: '//a[@href="/shop/add_to_cart/?item_qty_1[qty]=1&item_id_1=periodically_order&return_url=https://new-trial03.tamago-cart.com"]').click()
      end
      @driver.switch_to.default_content()
      # quantity = conversations.find_by_data_input_name('quantity').value
      # select_quantity = @driver.find_element(css: "select#select_order_qty_0")
      # choose_select_quantity = Selenium::WebDriver::Support::Select.new(select_quantity)
      # choose_select_quantity.select_by(:value, quantity)

      input = @driver.find_element(css: tamago_repeat_config.add_to_cart_button_selector)
      Log.info "\t\tinput.click"
      input.click()
    end

    def entry_login_page
      Log.info "\tentry_login_page"
      Log.info "\t\tdriver.switch_to.default_content()"
      @driver.switch_to.default_content()
      # recaptcha_page
      #sleep(5)
      # Log.info "\t\tdriver.find_element(name: \"shipping_address[family_name]\")"
      family_name = @driver.find_element(name: "shipping_address[family_name]")
      # Log.info "\t\tfamily_name.send_keys(#{conversations.find_by_data_input_name('user_name').value})"
      data_name = JSON.parse(conversations.find_by_data_input_name('data_name').value)
      first_data = data_name[0]['text_input']['text']
      second_data = data_name[1]['text_input']['text']
      family_name.send_keys(first_data['valueLeft'])

      Log.info "\t\tdriver.find_element(name: \"shipping_address_first_name\")"
      first_name = @driver.find_element(id: "shipping_address_first_name")
      # Log.info "\t\tfirst_name.send_keys(#{conversations.find_by_data_input_name('user_name')&.value})"
      first_name.send_keys(first_data['valueRight'])

      # Log.info "\t\tdriver.find_element(name: \"shipping_address_family_name_kana\")"
      family_name_kana = @driver.find_element(id: "shipping_address_family_name_kana")
      # Log.info "\t\tfamily_name_kana.send_keys(#{conversations.find_by_data_input_name('user_name_kana')&.value})"
      family_name_kana.send_keys(second_data['valueLeft'])

      Log.info "\t\tdriver.find_element(name: \"shipping_address_first_name_kana\")"
      first_name_kana = @driver.find_element(id: "shipping_address_first_name_kana")
      Log.info "\t\tfirst_name_kana.send_keys(#{conversations.find_by_data_input_name('user_name_kana')&.value})"
      first_name_kana.send_keys(second_data['valueRight'])

      data_address = JSON.parse(conversations.find_by_data_input_name('zip_code_address').value)
      Log.info "\t\tdriver.find_element(name: \"shipping_address[zip]\")"
      shipping_address_zip = @driver.find_element(name: "shipping_address[zip]")
      post_code = data_address['post_code'].present? ? data_address['post_code'] : data_address['value_post_code']
      Log.info "\t\tshipping_address_zip.send_keys(#{post_code.gsub('-', '')})"
      shipping_address_zip.send_keys(post_code.gsub('-', ''))

      Log.info "\t\t@driver.find_element(id: \"hide_display_shipping_address a\").click()"
      @driver.find_element(id: "hide_display_shipping_address a").click()
      Log.info "\t\tsleep(5)"
      sleep(5)
      Log.info "\t\t@driver.find_element(name: \"shipping_address[address]\")"
      shipping_address_address = @driver.find_element(name: "shipping_address[address]")
      Log.info "\t\tshipping_address_address.send_keys(#{data_address['value_address']})"
      shipping_address_address.send_keys(data_address['value_address'])

      Log.info "\t\t@driver.find_element(name: \"shipping_address[building]\")"
      shipping_address_building = @driver.find_element(name: "shipping_address[building]")
      Log.info "\t\tshipping_address_building.send_keys(#{data_address['value_building_name']})"
      shipping_address_building.send_keys(data_address['value_building_name'])

      Log.info "\t\tdriver.find_element(id: \"shipping_address_tel\")"
      shipping_address_tel = @driver.find_element(id: "shipping_address_tel")
      Log.info "\t\tshipping_address_tel.send_keys(#{conversations.find_by_data_input_name('phone_number').value})"
      shipping_address_tel.send_keys(conversations.find_by_data_input_name('phone_number').value)

      if conversations.find_by_data_input_name('sex').value == 1
        Log.info "\t\t@driver.find_element(id: \"sex_1\").click()"
        @driver.find_element(id: "sex_1").click()
      else
        Log.info "\t\t@driver.find_element(id: \"sex_1\").click()"
        @driver.find_element(id: "sex_2").click()
      end
      birth_date = JSON.parse(conversations.find_by_data_input_name('birth_date').value)

      Log.info "\t\t@driver.find_element(id: \"user_birthday_1i\")"
      select_year = @driver.find_element(id: "user_birthday_1i")
      choose_select_year = Selenium::WebDriver::Support::Select.new(select_year)
      Log.info "\t\tchoose_select_year.select_by(:value, #{birth_date['valueYear']})"
      choose_select_year.select_by(:value, birth_date['valueYear'])

      Log.info "\t\t@driver.find_element(id: \"user_birthday_2i\")"
      select_month = @driver.find_element(id: "user_birthday_2i")
      choose_select_month = Selenium::WebDriver::Support::Select.new(select_month)
      Log.info "\t\tchoose_select_year.select_by(:value, #{birth_date['valueMonth']})"
      choose_select_month.select_by(:value, birth_date['valueMonth'].to_i.to_s)

      Log.info "\t\t@driver.find_element(id: \"user_birthday_3i\")"
      select_day = @driver.find_element(id: "user_birthday_3i")
      choose_select_day = Selenium::WebDriver::Support::Select.new(select_day)
      Log.info "\t\tchoose_select_year.select_by(:value, #{birth_date['valueDay']})"
      choose_select_day.select_by(:value, birth_date['valueDay'].to_i.to_s)

      Log.info "\t\t@driver.find_element(id: \"user_email\")"
      user_email = @driver.find_element(id: "user_email")
      Log.info "\t\tuser_email.send_keys(conversations.find_by_data_input_name('user_email').value)"
      user_email.send_keys(conversations.find_by_data_input_name('user_email').value)

      if tamago_repeat_config.email_confirm_required?
        Log.info "\t\t@driver.find_element(id: \"user_email_confirmation\")"
        user_email_confirmation = @driver.find_element(id: "user_email_confirmation")
        Log.info "\t\tuser_email_confirmation.send_keys(#{conversations.find_by_data_input_name('user_email').value})"
        user_email_confirmation.send_keys(conversations.find_by_data_input_name('user_email').value)
      end

      Log.info "\t\t@driver.find_element(id: \"user_password\")"
      user_password = @driver.find_element(id: "user_password")
      Log.info "\t\tuser_password.send_keys(#{conversations.find_by_data_input_name('user_password').value})"
      user_password.send_keys(conversations.find_by_data_input_name('user_password').value)

      Log.info "\t\t@driver.find_element(id: \"user_password_confirmation\")"
      user_password_confirmation = @driver.find_element(id: "user_password_confirmation")
      Log.info "\t\tuser_password_confirmation.send_keys(#{conversations.find_by_data_input_name('user_password').value})"
      user_password_confirmation.send_keys(conversations.find_by_data_input_name('user_password').value)

      Log.info "\t\t@driver.find_element(id: \"hide_display2\").click()"
      @driver.find_element(id: "hide_display2").click()
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

    def payment_page
      Log.info "\tpayment_page"
      Log.info "\t\tdriver.switch_to.default_content()"
      @driver.switch_to.default_content()
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
      Log.info "\t\t@driver.find_element(id: \"new_credit_card_number\")"
      card_number = @driver.find_element(id: "new_credit_card_number")
      Log.info "\t\tcard_number.send_keys(data_card['card_number'])"
      card_number.send_keys(data_card['card_number'])
      Log.info "\t\tcard_name = @driver.find_element(id: \"new_credit_card_name\")"
      card_name = @driver.find_element(id: "new_credit_card_name")
      Log.info "\t\tcard_name.send_keys(data_card['card_name'])"
      card_name.send_keys(data_card['card_name'])
      Log.info "\t\t@driver.find_element(id: \"new_credit_effective_date_2i\")"
      select_month = @driver.find_element(id: "new_credit_effective_date_2i")
      choose_select_month = Selenium::WebDriver::Support::Select.new(select_month)
      Log.info "\t\tchoose_select_month.select_by(:value, #{data_card['month']})"
      choose_select_month.select_by(:value, data_card['month'])

      Log.info "\t\t@driver.find_element(id: \"new_credit_effective_date_1i\")"
      select_year = @driver.find_element(id: "new_credit_effective_date_1i")
      choose_select_year = Selenium::WebDriver::Support::Select.new(select_year)
      Log.info "\t\tchoose_select_month.select_by(:value, #{data_card['year']})"
      choose_select_year.select_by(:value, data_card['year'])

      Log.info "\t\t@driver.find_element(id: \"new_credit_security_code\")"
      security_code = @driver.find_element(id: "new_credit_security_code")
      Log.info "\t\tsecurity_code.send_keys(#{data_card['cvc']})"
      security_code.send_keys(data_card['cvc'])

      if data_card['payment_method'][0] == 'jcb'
        @driver.find_element(id: "new_credit_card_brand_jcb").click()
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
      @driver.quit
    end
  end
end
