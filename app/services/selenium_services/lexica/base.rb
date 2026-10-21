require "selenium-webdriver"
require File.dirname(__FILE__) + "/../../log"

module SeleniumServices
  module Lexica
    class Base < SeleniumServices::Base
      TIMEOUT = 45

      def init_selenium_driver
        @log_tab_level += 1
        Selenium::WebDriver.logger.output = File.join("#{Rails.root}/log", "selenium.log")
        Selenium::WebDriver.logger.level = :debug
        Log.info "Init selenium driver for chrome", @log_tab_level
        options = Selenium::WebDriver::Chrome::Options.new(
          args: [
            "--lang=ja",
            "--headless=new",
            "--no-sandbox",
            "--disable-gpu",
            "--disable-dev-shm-usage",
            "--window-size=2560,1440",
            "--disable-extensions",
            "--disable-background-networking",
            "--disable-sync",
            "--disable-default-apps",
            "--no-first-run",
            "--mute-audio",
            "--disable-hang-monitor",
            "--disable-popup-blocking",
            "--disable-prompt-on-repost",
            "--disable-component-update",
            "--metrics-recording-only",
            "--disable-features=TranslateUI",
            "--disable-blink-features=AutomationControlled",
            "--user-agent=#{desktop_user_agent}",
          ],
        )
        options.exclude_switches = ["enable-automation"]
        chrome_bin = ENV["CHROME_BIN"].to_s.strip
        options.binary = chrome_bin if chrome_bin.present?

        driver_path = ENV["CHROMEDRIVER_PATH"].to_s.strip
        service =
          if driver_path.present?
            Selenium::WebDriver::Chrome::Service.new(path: driver_path)
          end

        @driver =
          if service
            Selenium::WebDriver.for(:chrome, options: options, service: service)
          else
            Selenium::WebDriver.for(:chrome, options: options)
          end
        @driver.execute_cdp("Network.enable")
        @driver.execute_cdp(
          "Network.setBlockedURLs",
          urls: [
            "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.svg", "*.ico",
            "*google-analytics*", "*googletagmanager*", "*doubleclick*",
            "*facebook.net*", "*hotjar*",
          ]
        )
        @driver.execute_cdp(
          "Page.addScriptToEvaluateOnNewDocument",
          source: "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"
        )
        Log.info @driver.execute_script("return navigator.userAgent"), @log_tab_level
        @driver.manage.timeouts.implicit_wait = 0
        @driver.manage.delete_all_cookies
        Log.info "Init OK selenium driver", @log_tab_level
        @log_tab_level -= 1
      end

      def capture(is_capture = true)
        sleep 0.2
        @step += 1
      end

      private

      def write_png(path)
        2.times do |attempt|
          @driver.save_screenshot(path)
          return if File.file?(path) && File.size(path) >= 32

          sleep 1 if attempt.zero?
        end
      end

      def desktop_user_agent
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36"
      end
    end
  end
end
