require 'selenium-webdriver'

module TamagoScenario
  class SeleniumService
    SECRET_KEY = Rails.application.secrets.secret_refresh_token
    attr_accessor :scenario, :conversations, :driver, :tamago_repeat_config

    def initialize(scenario, conversations)
      @scenario = scenario
      @conversations = conversations
      # proxy = Selenium::WebDriver::Proxy.new( socks: '127.0.0.1:9050',socks_version: 5)
      # caps = Selenium::WebDriver::Remote::Capabilities.chrome(proxy: proxy)
      # @driver = Selenium::WebDriver.for :chrome, capabilities: caps
      @driver = Selenium::WebDriver.for :chrome
      @tamago_repeat_config = @scenario.tamago_repeat_config
    end

    def process
      cart_page
      entry_login_page
      payment_page
      confirm_page
    end

    def cart_page
      @driver.navigate.to tamago_repeat_config.tamago_landing_page_url
      input = @driver.find_element(css: tamago_repeat_config.add_to_cart_button_selector)
      input.click()
    end

    def entry_login_page
      @driver.switch_to.default_content()
      # recaptcha_page
      #sleep(5)
      family_name = @driver.find_element(name: "shipping_address[family_name]")
      family_name.send_keys(conversations.find_by_data_input_name('user_name').value)

      first_name = @driver.find_element(id: "shipping_address_first_name")
      first_name.send_keys(conversations.find_by_data_input_name('user_name').value)

      family_name_kana = @driver.find_element(id: "shipping_address_family_name_kana")
      family_name_kana.send_keys(conversations.find_by_data_input_name('user_name_kana').value)

      first_name_kana = @driver.find_element(id: "shipping_address_first_name_kana")
      first_name_kana.send_keys(conversations.find_by_data_input_name('user_name_kana').value)

      data_address = JSON.parse(conversations.find_by_data_input_name('zip_code_address').value)
      shipping_address_zip = @driver.find_element(name: "shipping_address[zip]")
      shipping_address_zip.send_keys(data_address['post_code'].gsub('-', ''))

      @driver.find_element(id: "hide_display_shipping_address a").click()
      sleep(5)
      shipping_address_address = @driver.find_element(name: "shipping_address[address]")
      shipping_address_address.send_keys(data_address['value_address'])

      shipping_address_building = @driver.find_element(name: "shipping_address[building]")
      shipping_address_building.send_keys(data_address['value_building_name'])

      shipping_address_tel = @driver.find_element(id: "shipping_address_tel")
      shipping_address_tel.send_keys(conversations.find_by_data_input_name('phone_number').value)
      if conversations.find_by_data_input_name('sex').value == 1
        @driver.find_element(id: "sex_1").click()
      else
        @driver.find_element(id: "sex_2").click()
      end
      birth_date = conversations.find_by_data_input_name('birth_date').value
      birth_date = Date.parse(birth_date)
      select_year = @driver.find_element(id: "user_birthday_1i")
      choose_select_year = Selenium::WebDriver::Support::Select.new(select_year)
      choose_select_year.select_by(:value, birth_date.year.to_s)

      select_month = @driver.find_element(id: "user_birthday_2i")
      choose_select_month = Selenium::WebDriver::Support::Select.new(select_month)
      choose_select_month.select_by(:value, birth_date.month.to_s)

      select_day = @driver.find_element(id: "user_birthday_3i")
      choose_select_day = Selenium::WebDriver::Support::Select.new(select_day)
      choose_select_day.select_by(:value, birth_date.day.to_s)

      user_email = @driver.find_element(id: "user_email")
      user_email.send_keys(conversations.find_by_data_input_name('user_email').value)

      if tamago_repeat_config.require_email_confirm?
        user_email_confirmation = @driver.find_element(id: "user_email_confirmation")
        user_email_confirmation.send_keys(conversations.find_by_data_input_name('user_email').value)
      end

      user_password = @driver.find_element(id: "user_password")
      user_password.send_keys(conversations.find_by_data_input_name('user_password').value)

      user_password_confirmation = @driver.find_element(id: "user_password_confirmation")
      user_password_confirmation.send_keys(conversations.find_by_data_input_name('user_password').value)

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
      @driver.switch_to.default_content()
      if conversations.find_by_data_input_name('credit_card_payment').present?
        @driver.find_element(id: "order_payment_method_id_2").click()
        @driver.find_element(css: "input#hide_display").click()
        credit_card_page
      else
        @driver.find_element(id: "order_payment_method_id_1").click()
      end
      @driver.find_element(css: "input#hide_display").click()
    end

    def credit_card_page
      @driver.switch_to.default_content()
      # recaptcha_page
      data_card = conversations.find_by_data_input_name('credit_card_payment').value
      data_card = JSON.parse(JWT.decode(data_card, SECRET_KEY)[0]["data"])
      card_number = @driver.find_element(id: "new_credit_card_number")
      card_number.send_keys(data_card['card_number'])
      card_name = @driver.find_element(id: "new_credit_card_name")
      card_name.send_keys(data_card['card_name'])
      select_month = @driver.find_element(id: "new_credit_effective_date_2i")
      choose_select_month = Selenium::WebDriver::Support::Select.new(select_month)
      choose_select_month.select_by(:value, data_card['month'])

      select_year = @driver.find_element(id: "new_credit_effective_date_1i")
      choose_select_year = Selenium::WebDriver::Support::Select.new(select_year)
      choose_select_year.select_by(:value, data_card['year'])

      security_code = @driver.find_element(id: "new_credit_security_code")
      security_code.send_keys(data_card['cvc'])
      if data_card['payment_method'][0] == 'jcb'
        @driver.find_element(id: "new_credit_card_brand_jcb").click()
      end
      @driver.find_element(css: "input#hide_display").click()
    end

    def confirm_page
      @driver.switch_to.default_content()
      sleep(5)
      @driver.find_element(css: "input#hide_display1").click()
    end
  end
end
