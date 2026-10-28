require "base64"
require "fileutils"
require "selenium-webdriver"
require File.dirname(__FILE__) + "/../../log"

module SeleniumServices
  module Lexica
    class Base < SeleniumServices::Base
      TIMEOUT = 45
      WINDOW_SIZE = "1280,720"
      BLOCKED_URLS = [
        "*google-analytics*", "*googletagmanager*", "*doubleclick*",
        "*facebook.net*", "*hotjar*",
        "*.png*", "*.jpg*", "*.jpeg*", "*.gif*", "*.webp*", "*.svg*", "*.ico*", "*.avif*"
      ].freeze

      def initialize(scenario, conversations, sink: nil)
        conversation_ids = conversations.map { |row| row.respond_to?(:id) ? row.id : row.data_input_name }
        Log.info "Start selenium service for: \n\tscenario: #{scenario.id}\n\tconversations: #{conversation_ids.inspect}"
        @scenario = scenario
        @conversations = conversations.to_a
        @user_input_id = @conversations.first&.user_input_id.presence || "sample"
        @tamago_repeat_config = @scenario.respond_to?(:tamago_repeat_config) ? @scenario.tamago_repeat_config : nil
        @screenshot_path = ENV["SELENIUM_SCREENSHOT_DIR"].to_s.strip
        @screenshot_path = File.join(Rails.root.to_s, "tmp", "selenium") if @screenshot_path.empty?
        @step = 1
        @current_frame = nil
        @log_tab_level = 0
        @is_error = nil
        @order_submitted_marked = false
        @selenium_result = sink || ActiveRecordResultSink.for_user_input(@user_input_id)
        extract_conversions_data
        init_selenium_driver
      end

      def init_selenium_driver
        @log_tab_level += 1
        selenium_log = ENV["SELENIUM_LOG"].to_s.strip
        Selenium::WebDriver.logger.output =
          if selenium_log.empty?
            File.join(Rails.root.to_s, "log", "selenium.log")
          else
            selenium_log
          end
        Selenium::WebDriver.logger.level = :debug
        Log.info "Init selenium driver for chrome", @log_tab_level
        chrome_args = [
          "--lang=ja",
          "--headless=new",
          "--no-sandbox",
          "--disable-gpu",
          "--disable-dev-shm-usage",
          "--window-size=#{WINDOW_SIZE}",
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
        ]
        chrome_args.concat(lambda_chrome_args) if lambda_runtime?
        options = Selenium::WebDriver::Chrome::Options.new(args: chrome_args)
        options.exclude_switches = ["enable-automation"]
        chrome_bin = ENV["CHROME_BIN"].to_s.strip
        options.binary = chrome_bin if chrome_bin.present?

        driver_path = ENV["CHROMEDRIVER_PATH"].to_s.strip
        service =
          if driver_path.present?
            Selenium::WebDriver::Chrome::Service.new(path: driver_path, args: chromedriver_log_args)
          elsif lambda_runtime?
            Selenium::WebDriver::Chrome::Service.new(args: chromedriver_log_args)
          end

        @driver =
          if service
            Selenium::WebDriver.for(:chrome, options: options, service: service)
          else
            Selenium::WebDriver.for(:chrome, options: options)
          end
        if ENV["AWS_LAMBDA_FUNCTION_NAME"].to_s == ""
          @driver.execute_cdp("Network.enable")
          @driver.execute_cdp(
            "Network.setBlockedURLs",
            urls: BLOCKED_URLS
          )
          @driver.execute_cdp(
            "Page.addScriptToEvaluateOnNewDocument",
            source: "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"
          )
        end
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

      def lambda_runtime?
        ENV["AWS_LAMBDA_FUNCTION_NAME"].to_s != ""
      end

      # Chrome 136+ ignores the DevTools port on the default profile, and crashpad
      # aborts the tab when it cannot write. Lambda can only write under /tmp.
      def lambda_chrome_args
        stamp = "#{Process.pid}-#{Time.now.to_i}"
        home = "/tmp/chrome-home-#{stamp}"
        profile = "/tmp/chrome-profile-#{stamp}"
        cache = "/tmp/chrome-cache-#{stamp}"
        crashes = "/tmp/chrome-crashes-#{stamp}"
        [home, profile, cache, crashes].each { |dir| FileUtils.mkdir_p(dir) }
        ENV["HOME"] = home
        ENV["XDG_CONFIG_HOME"] = home
        ENV["XDG_CACHE_HOME"] = cache
        ENV["CHROME_LOG_FILE"] = "/tmp/chrome.log"
        [
          "--user-data-dir=#{profile}",
          "--disk-cache-dir=#{cache}",
          "--crash-dumps-dir=#{crashes}",
          "--disable-crash-reporter",
          "--disable-breakpad",
          "--no-report-upload",
          "--single-process",
          "--no-zygote",
          "--disable-setuid-sandbox",
          "--disable-gpu-sandbox",
          "--in-process-gpu",
          "--disable-software-rasterizer",
          "--disable-features=VizDisplayCompositor,AudioServiceOutOfProcess,IsolateOrigins,site-per-process,TranslateUI",
        ]
      end

      def chromedriver_log_args
        return [] unless lambda_runtime?

        ["--log-path=/tmp/chromedriver.log", "--log-level=INFO"]
      end
    end
  end
end
