module Lexica
  class ClientChromeLimit
    def self.clamp_permitted!(permitted)
      return permitted unless permitted.is_a?(ActionController::Parameters) || permitted.is_a?(Hash)

      if permitted[:lexica_max_chrome].present?
        global = SystemSetting.lexica_max_chrome
        permitted[:lexica_max_chrome] = [
          SystemSetting.clamp_chrome(permitted[:lexica_max_chrome]),
          global
        ].min
      elsif permitted.key?(:lexica_max_chrome) && permitted[:lexica_max_chrome].blank?
        permitted[:lexica_max_chrome] = nil
      end
      permitted
    end

    def self.read_global
      SystemSetting.lexica_max_chrome
    end

    def self.write_global(value)
      SystemSetting.lexica_max_chrome = value
    end
  end
end
