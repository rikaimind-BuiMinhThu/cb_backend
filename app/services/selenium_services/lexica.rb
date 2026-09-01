module SeleniumServices
  module Lexica
    PATHS = %w[first_time new existing].freeze

    def self.build(scenario, conversations)
      path = extract_path(conversations)
      klass =
        case path
        when "first_time" then FirstTime
        when "new" then NewMember
        when "existing" then Existing
        else
          raise ArgumentError, "unknown lexica path: #{path.inspect}"
        end
      klass.new(scenario, conversations)
    end

    def self.extract_path(conversations)
      raw = conversations.detect { |c| %w[path order_path].include?(c.data_input_name.to_s) }&.value
      value = raw.to_s
      return value if PATHS.include?(value)

      mapped = {
        "1" => "first_time",
        "2" => "new",
        "3" => "existing",
        "はじめて" => "first_time",
        "新規会員" => "new",
        "既存会員" => "existing"
      }[value]
      mapped || "existing"
    end
  end
end
