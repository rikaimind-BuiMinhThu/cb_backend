require 'selenium-webdriver'

module TamagoScenario
  class SeleniumService
    SECRET_KEY = Rails.application.secrets.secret_refresh_token
    attr_accessor :scenario, :conversation, :driver, :tamago_repeat_config
    def initialize(scenario, conversations)
      @scenario = scenario
      @conversations = conversations
      @driver = Selenium::WebDriver.for :chrome
      @tamago_repeat_config = nil
    end

    def process
      cart_page
      entry_login_page
      payment_page
    end

    def cart_page
      @driver.navigate.to 'https://gardenbotanica.jp/shop/add_to_cart/?item_qty_1[qty]=1&item_id_1=order&return_url=https://gardenbotanica.jp'
      sleep(5)
      input = @driver.find_element(css: 'input#hide_display')
      input.click()
      sleep(5)
    end

    def entry_login_page
      @driver.switch_to.default_content()
      recaptcha_page
      sleep(3)
      @driver.find_element(id: "shipping_address_family_name")
      @driver.send_keys(conversation.find_by_data_input_name('user_name').value)

      @driver.find_element(id: "shipping_address_first_name")
      @driver.send_keys(conversation.find_by_data_input_name('user_name').value)

      @driver.find_element(id: "shipping_address_family_name_kana")
      @driver.send_keys(conversation.find_by_data_input_name('user_name_kana').value)

      @driver.find_element(id: "shipping_address_first_name_kana")
      @driver.send_keys(conversation.find_by_data_input_name('user_name_kana').value)

      data_address = JSON.parse(conversation.find_by_data_input_name('zip_code_address').value)
      @driver.find_element(id: "shipping_address_zip")
      @driver.send_keys(data_address['post_code'].gsub('-', ''))

      @driver.find_element(id: "hide_display_shipping_address a").click()

      @driver.find_element(id: "shipping_address_building")
      @driver.send_keys(data_address['value_building_name'])

      @driver.find_element(id: "shipping_address_tel")
      @driver.send_keys(conversation.find_by_data_input_name('phone_number').value)
      if conversation.find_by_data_input_name('sex').value == 1
        @driver.find_element(id: "sex_1").click()
      else
        @driver.find_element(id: "sex_2").click()
      end
      birth_date = conversation.find_by_data_input_name('birth_date').value
      birth_date = Date.parse(birth_date)
      select_year = @driver.find_element(id: "user_birthday_1i")
      all_options = select_year.find_elements(:tag_name, "option")
      all_options.each do |option|
        if option == birth_date.year.to_s
          option.click()
          break
        end
      end

      select_month = @driver.find_element(id: "user_birthday_2i")
      all_options = select_month.find_elements(:tag_name, "option")
      all_options.each do |option|
        if option == birth_date.month.to_s
          option.click()
          break
        end
      end

      select_day = @driver.find_element(id: "user_birthday_3i")
      all_options = select_day.find_elements(:tag_name, "option")
      all_options.each do |option|
        if option == birth_date.day.to_s
          option.click()
          break
        end
      end

      @driver.find_element(id: "user_email")
      @driver.send_keys(conversation.find_by_data_input_name('user_email').value)

      @driver.find_element(id: "user_email_confirmation")
      @driver.send_keys(conversation.find_by_data_input_name('user_email').value)

      @driver.find_element(id: "user_password")
      @driver.send_keys(conversation.find_by_data_input_name('user_password').value)

      @driver.find_element(id: "user_password_confirmation")
      @driver.send_keys(conversation.find_by_data_input_name('user_password').value)

      @driver.find_element(id: "hide_display2").click()
      sleep(5)
    end

    def recaptcha_page
      frame = @driver.find_element(css: "iframe[title^='recaptcha']")
      sleep(5)
      @driver.switch_to.frame(frame)
      @driver.find_element(id: "recaptcha-audio-button").click()
      sleep(5)
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
      if credit_card
        @driver.find_element(id: "order_payment_method_id_2").click()
        @driver.find_element(css: "input#hide_display").click()
        credit_card_page
      else
        @driver.find_element(id: "order_payment_method_id_1").click()
      end
    end

    def credit_card_page
      @driver.switch_to.default_content()
      recaptcha_page
      data_card = conversation.find_by_data_input_name('credit_card_payment').value
      data_card = JSON.parse(JWT.decode(data_card, SECRET_KEY)[0]["data"])
      @driver.find_element(id: "new_credit_card_number")
      @driver.send_keys(data_card['card_number'])
      @driver.find_element(id: "new_credit_card_name")
      @driver.send_keys(data_card['card_name'])
      select_month = @driver.find_element(id: "new_credit_effective_date_2i")
      all_options = select_month.find_elements(:tag_name, "option")
      all_options.each do |option|
        if option == data_card['month']
          option.click()
          break
        end
      end

      select_year = @driver.find_element(id: "new_credit_effective_date_1i")
      all_options = select_year.find_elements(:tag_name, "option")
      all_options.each do |option|
        if option == data_card['year']
          option.click()
          break
        end
      end
      @driver.find_element(id: "new_credit_security_code")
      @driver.send_keys(data_card['cvc'])
      if data_card['payment_method'][0] == 'jcb'
        @driver.find_element(id: "new_credit_card_brand_jcb").click()
      end
      @driver.find_element(css: "input#hide_display").click()
    end

    def confirm_page
      @driver.switch_to.default_content()
      @driver.find_element(css: "input#hide_display1").click()
    end
  end
end
