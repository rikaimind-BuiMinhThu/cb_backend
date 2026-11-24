require "test_helper"
require_relative "../../app/services/lexica/url_safety"

class LexicaUrlSafetyTest < ActiveSupport::TestCase
  test "allows https mirai cart and shop hosts" do
    assert Lexica::UrlSafety.allowed?("https://cart.mirai-japan.co.jp/")
    assert Lexica::UrlSafety.allowed?("https://mirai-japan.co.jp/path")
    assert Lexica::UrlSafety.allowed?("https://lp.mirai-japan.co.jp/ab/x")
  end

  test "rejects http, private, and foreign hosts" do
    assert_not Lexica::UrlSafety.allowed?("http://cart.mirai-japan.co.jp/")
    assert_not Lexica::UrlSafety.allowed?("https://169.254.169.254/latest/meta-data")
    assert_not Lexica::UrlSafety.allowed?("https://evil.example/")
    assert_not Lexica::UrlSafety.allowed?("javascript:alert(1)")
  end

  test "assert_allowed! raises for unsafe urls" do
    assert_raises(ArgumentError) do
      Lexica::UrlSafety.assert_allowed!("https://evil.example/", field: :lexica_cart_url)
    end
  end
end
