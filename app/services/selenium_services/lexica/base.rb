require "base64"
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
        @step += 1
        return unless is_capture
        return unless @driver

        FileUtils.mkdir_p(@screenshot_path)
        path = File.join(@screenshot_path, "#{@scenario.id}_#{@user_input_id}_#{@step}.png")
        write_png(path)
        Log.info "#{@step}: capture #{path}", @log_tab_level
      rescue StandardError => error
        Log.error "#{@step}: capture failed: #{error.message}", @log_tab_level
      end

      private

      def write_png(path)
        2.times do |attempt|
          bytes = full_page_png
          File.binwrite(path, bytes) if bytes && bytes.bytesize >= 32
          @driver.save_screenshot(path) unless File.file?(path) && File.size(path) >= 32
          return if File.file?(path) && File.size(path) >= 32

          sleep 1 if attempt.zero?
        end
      end

      def full_page_png
        metrics = @driver.execute_cdp("Page.getLayoutMetrics")
        size = metrics["cssContentSize"] || metrics["contentSize"] || {}
        width = size["width"].to_f
        height = [size["height"].to_f, 16_000].min
        return nil if width < 1 || height < 1

        shot = @driver.execute_cdp(
          "Page.captureScreenshot",
          format: "png",
          captureBeyondViewport: true,
          clip: { x: 0, y: 0, width: width, height: height, scale: 1 }
        )
        Base64.decode64(shot["data"].to_s)
      rescue StandardError => error
        Log.error "full page capture failed: #{error.message}", @log_tab_level
        nil
      end

      def desktop_user_agent
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36"
      end
    end
  end
end
