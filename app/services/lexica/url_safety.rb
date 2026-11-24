require "uri"

module Lexica
  # Restrict RPA navigation targets to https Lexica shop/cart hosts.
  module UrlSafety
    DEFAULT_HOST_SUFFIXES = %w[
      mirai-japan.co.jp
    ].freeze

    module_function

    def host_suffixes
      raw = ENV["LEXICA_ALLOWED_URL_HOST_SUFFIXES"].to_s
      return DEFAULT_HOST_SUFFIXES if raw.blank?

      raw.split(",").map { |part| part.strip.downcase }.reject(&:blank?)
    end

    def normalize(url)
      value = url.to_s.strip
      value.empty? ? nil : value
    end

    def allowed?(url)
      value = normalize(url)
      return true if value.nil?

      uri = URI.parse(value)
      return false unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      return false unless uri.scheme.to_s.downcase == "https"
      return false if uri.host.blank?
      return false if uri.userinfo.present?

      host = uri.host.to_s.downcase
      host_suffixes.any? { |suffix| host == suffix || host.end_with?(".#{suffix}") }
    rescue URI::InvalidURIError
      false
    end

    def assert_allowed!(url, field:)
      return if allowed?(url)

      raise ArgumentError, "#{field} must be an https URL on an allowed Lexica host"
    end
  end
end
