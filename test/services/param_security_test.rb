# frozen_string_literal: true

require "test_helper"

class ParamSecurityTest < ActiveSupport::TestCase
  test "encrypt roundtrip" do
    config = ParamSecurity.validate_config!(
      mode: "encrypt",
      params: ["password"],
      key: "secretkey123",
    )
    cipher = ParamSecurity.encrypt("plain-secret", config)
    assert ParamSecurity.ciphertext?(cipher)
    assert_equal "plain-secret", ParamSecurity.decrypt!(cipher, config)
  end

  test "hash config stores bcrypt algorithm and does not decode" do
    config = ParamSecurity.validate_config!(
      mode: "hash",
      params: ["password"],
      salt: "pepper",
    )
    assert_equal "hash", config["mode"]
    assert_equal "bcrypt", config["algorithm"]
    assert ParamSecurity.hash_mode?(config)
    refute ParamSecurity.encrypt_mode?(config)
  end

  test "bad ciphertext rejected" do
    config = ParamSecurity.validate_config!(
      mode: "encrypt",
      params: ["password"],
      key: "secretkey123",
    )
    assert_raises(ParamSecurity::Error) do
      ParamSecurity.decrypt!("aes256gcm:v1:not-valid-base64!!!", config)
    end
  end

  test "encrypt requires key and params" do
    error = assert_raises(ParamSecurity::Error) do
      ParamSecurity.validate_config!(mode: "encrypt", params: [], key: "short")
    end
    assert_equal "param_security_invalid_config", error.code
  end

  test "reveal returns jwt payload data and skips bcrypt" do
    payload = { "data" => "my-password", "exp" => (Time.current + 1.hour).to_i }
    token = JWT.encode(payload, ScenarioUserResponse::SECRET_KEY)
    assert_equal "my-password", ParamSecurity.reveal(token)

    assert_nil ParamSecurity.reveal("$2a$12$abcdefghijklmnopqrstuv")
    assert_equal "plain", ParamSecurity.reveal("plain")
  end

  test "none mode does not cover fields" do
    config = ParamSecurity.normalize(mode: "none")
    refute ParamSecurity.covers?(config, "password")
  end
end
