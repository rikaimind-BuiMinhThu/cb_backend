# frozen_string_literal: true

require "openssl"
require "base64"
require "digest"

class ParamSecurity
  PREFIX = "aes256gcm:v1:"
  IV_LEN = 12
  TAG_LEN = 16
  MIN_KEY_LEN = 8
  MODES = %w[none hash encrypt].freeze
  ALGORITHMS = {
    "hash" => "bcrypt",
    "encrypt" => "aes-256-gcm",
  }.freeze

  class Error < StandardError
    attr_reader :code

    def initialize(code, message)
      @code = code
      super(message)
    end
  end

  def self.default_config
    {
      "mode" => "none",
      "algorithm" => nil,
      "params" => [],
      "key" => nil,
      "salt" => nil,
    }
  end

  def self.normalize(raw)
    raw = {} if raw.blank?
    raw = raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)
    raw = raw.with_indifferent_access if raw.respond_to?(:with_indifferent_access)

    mode = (raw[:mode] || raw["mode"] || "none").to_s
    mode = "none" unless MODES.include?(mode)

    params = Array(raw[:params] || raw["params"]).map(&:to_s).map(&:strip).reject(&:blank?).uniq
    key = raw[:key] || raw["key"]
    key = key.present? ? key.to_s : nil
    salt = raw[:salt] || raw["salt"]
    salt = salt.present? ? salt.to_s : nil

    algorithm =
      case mode
      when "hash" then ALGORITHMS["hash"]
      when "encrypt" then ALGORITHMS["encrypt"]
      else nil
      end

    {
      "mode" => mode,
      "algorithm" => algorithm,
      "params" => params,
      "key" => key,
      "salt" => salt,
    }
  end

  def self.validate_config!(raw)
    config = normalize(raw)
    mode = config["mode"]

    return config if mode == "none"

    # params list is unused: when mode is hash/encrypt, all fields are covered.

    if mode == "encrypt"
      if config["key"].blank? || config["key"].length < MIN_KEY_LEN
        raise Error.new("param_security_invalid_config", "key required (min #{MIN_KEY_LEN} chars) for encrypt")
      end
      if config["algorithm"] != ALGORITHMS["encrypt"]
        raise Error.new("param_security_invalid_config", "algorithm must be aes-256-gcm for encrypt")
      end
    end

    if mode == "hash" && config["algorithm"] != ALGORITHMS["hash"]
      raise Error.new("param_security_invalid_config", "algorithm must be bcrypt for hash")
    end

    config
  end

  def self.config_for(scenario)
    return default_config if scenario.blank?

    normalize(scenario.extra_config_hash["param_security"])
  rescue StandardError
    default_config
  end

  def self.covers?(config, _data_input_name = nil)
    config = normalize(config)
    config["mode"] != "none"
  end

  def self.encrypt_mode?(config)
    normalize(config)["mode"] == "encrypt"
  end

  def self.hash_mode?(config)
    normalize(config)["mode"] == "hash"
  end

  def self.ciphertext?(value)
    value.is_a?(String) && value.start_with?(PREFIX)
  end

  def self.bcrypt_string?(value)
    value.is_a?(String) && value.start_with?("$2")
  end

  def self.jwt_string?(value)
    value.is_a?(String) && value.count(".") == 2 && value.split(".").all?(&:present?)
  end

  def self.derive_key(key_string)
    Digest::SHA256.digest(key_string.to_s)
  end

  def self.encrypt(plaintext, config)
    config = normalize(config)
    raise Error.new("param_security_invalid_config", "encrypt requires key") if config["key"].blank?

    iv = OpenSSL::Random.random_bytes(IV_LEN)
    cipher = OpenSSL::Cipher.new("aes-256-gcm")
    cipher.encrypt
    cipher.key = derive_key(config["key"])
    cipher.iv = iv
    encrypted = cipher.update(plaintext.to_s) + cipher.final
    tag = cipher.auth_tag
    PREFIX + Base64.strict_encode64(iv + encrypted + tag)
  end

  def self.decrypt!(ciphertext, config)
    config = normalize(config)
    raise Error.new("param_security_invalid_format", "not ciphertext") unless ciphertext?(ciphertext)
    raise Error.new("param_security_invalid_config", "encrypt requires key") if config["key"].blank?

    blob = Base64.strict_decode64(ciphertext.delete_prefix(PREFIX))
    if blob.bytesize < IV_LEN + TAG_LEN + 1
      raise Error.new("param_security_invalid_format", "ciphertext too short")
    end

    iv = blob.byteslice(0, IV_LEN)
    tag = blob.byteslice(-TAG_LEN, TAG_LEN)
    encrypted = blob.byteslice(IV_LEN...-TAG_LEN)

    cipher = OpenSSL::Cipher.new("aes-256-gcm")
    cipher.decrypt
    cipher.key = derive_key(config["key"])
    cipher.iv = iv
    cipher.auth_tag = tag
    cipher.update(encrypted) + cipher.final
  rescue Error
    raise
  rescue StandardError => e
    raise Error.new("param_security_decode_failed", e.message)
  end

  def self.decrypt_tree!(node, config)
    case node
    when ActionController::Parameters
      decrypt_tree!(node.to_unsafe_h, config)
    when Hash
      node.each do |key, value|
        node[key] = decrypt_tree!(value, config)
      end
      node
    when Array
      node.map! { |value| decrypt_tree!(value, config) }
      node
    when String
      ciphertext?(node) ? decrypt!(node, config) : node
    else
      node
    end
  end

  def self.outbound_records(records, config)
    config = normalize(config)
    Array(records).map { |record| outbound_record(record, config) }
  end

  def self.outbound_record(record, config)
    payload = record.as_json
    return payload unless encrypt_mode?(config) && covers?(config, record.data_input_name)

    raw = record.value
    return payload if raw.blank? || ciphertext?(raw)

    encrypted = encrypt(raw, config)
    case record.class.list[record.data_input_name&.to_sym]&.dig(:value_type)
    when :text
      payload["text_value"] = encrypted
    when :string
      payload["string_value"] = encrypted
    else
      if payload.key?("text_value") && payload["text_value"].present?
        payload["text_value"] = encrypted
      elsif payload.key?("string_value")
        payload["string_value"] = encrypted
      end
    end
    payload
  end

  def self.reveal(stored_value, secret_key: ScenarioUserResponse::SECRET_KEY)
    return nil if stored_value.blank?
    return nil if bcrypt_string?(stored_value)

    if jwt_string?(stored_value)
      begin
        return JWT.decode(stored_value, secret_key)[0]["data"]
      rescue StandardError
        return stored_value
      end
    end

    stored_value
  end
end
