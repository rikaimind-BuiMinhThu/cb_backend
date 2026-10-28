require "pathname"
require "logger"
require "json"
require "fileutils"
require "ostruct"
require "active_support"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/time/calculations"

module Rails
  class ApplicationShim
    def secrets
      @secrets ||= OpenStruct.new(secret_refresh_token: ENV.fetch("SECRET_REFRESH_TOKEN", "lambda"))
    end
  end

  class << self
    def root
      Pathname.new(ENV.fetch("RAILS_ROOT", "/var/task"))
    end

    def logger
      @logger ||= Logger.new($stdout)
    end

    def application
      @application ||= ApplicationShim.new
    end
  end
end

module Settings
  def self.two_captcha
    Struct.new(:api_key).new(ENV["TWO_CAPTCHA_API_KEY"].to_s)
  end
end

module ActiveModel
  module Type
    class Boolean
      FALSE_VALUES = [false, 0, "0", "f", "F", "false", "FALSE", "off", "OFF"].freeze

      def cast(value)
        return nil if value.nil?

        !FALSE_VALUES.include?(value)
      end
    end
  end
end
