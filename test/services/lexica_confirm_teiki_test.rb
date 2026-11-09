require "test_helper"
require "ostruct"
require "json"

class LexicaConfirmTeikiTest < ActiveSupport::TestCase
  # LexicaStop lives in checkout.rb; touch Checkout so Zeitwerk loads it.
  SeleniumServices::Lexica::Checkout

  class Harness
    include SeleniumServices::Lexica::CompleteOrder

    public :confirm_review_page

    attr_accessor :driver, :click_confirm_teiki, :confirm_teiki_applied, :offer_surfaces,
                  :scenario, :selenium_result, :sku, :log_tab_level
    attr_reader :clicks, :upsell_calls, :blocked_banner

    def initialize(urls:, blocked: nil, offer_flag: true)
      @urls = urls.dup
      @url_index = 0
      @blocked_banner = blocked
      @offer_flag = offer_flag
      @click_confirm_teiki = false
      @confirm_teiki_applied = false
      @offer_surfaces = []
      @sku = "_P046"
      @log_tab_level = 0
      @clicks = []
      @upsell_calls = 0
      @selenium_result = OpenStruct.new(resolved_sku: nil, offer_surfaces: nil)
      @driver = Object.new
      harness = self
      @driver.define_singleton_method(:current_url) { harness.current_url }
      @driver.define_singleton_method(:page_source) { "" }
    end

    def current_url
      @urls[[@url_index, @urls.length - 1].min].to_s
    end

    def advance_url!
      @url_index += 1 if @url_index < @urls.length - 1
    end

    def apply_confirm_upsell
      @upsell_calls += 1
      return unless @click_confirm_teiki

      unless @offer_flag
        raise SeleniumServices::Lexica::LexicaStop.new(
          "confirm_upsell_disabled",
          "チャットでアップセル選択済みですが confirm upsell が無効です"
        )
      end

      @confirm_teiki_applied = true
      @offer_surfaces |= ["confirm_upsell"]
      snapshot_confirm_teiki!
    end

    def snapshot_confirm_teiki!
      @selenium_result.resolved_sku = @sku.to_s
      @selenium_result.offer_surfaces = JSON.generate(Array(@offer_surfaces))
    end

    def purchase_blocked_banner
      @blocked_banner
    end

    def submit_button_by_text
      "button.btn-submit-checkout"
    end

    def click(selector, label, **_opts)
      @clicks << [selector, label]
      advance_url! if label.to_s == "confirm order"
    end

    def thanks_page?(url, _source)
      url.to_s.include?("/order/complete")
    end
  end

  def test_entry_then_confirm_applies_teiki_before_final_submit
    harness = Harness.new(
      urls: [
        "https://cart.example.test/order/entry",
        "https://cart.example.test/order/confirm",
        "https://cart.example.test/order/complete?code=1"
      ]
    )
    harness.click_confirm_teiki = true
    harness.confirm_review_page

    assert_equal 1, harness.upsell_calls
    assert_equal true, harness.confirm_teiki_applied
    assert_includes harness.offer_surfaces, "confirm_upsell"
    assert_equal(
      [
        ["button.btn-submit-checkout", "confirm order"],
        ["button.btn-submit-checkout", "confirm order"]
      ],
      harness.clicks
    )
  end

  def test_confirm_with_blocked_banner_still_runs_teiki_first
    harness = Harness.new(
      urls: [
        "https://cart.example.test/order/confirm",
        "https://cart.example.test/order/complete?code=1"
      ],
      blocked: "配送条件を満たしていないため購入いただけません。"
    )
    harness.click_confirm_teiki = true

    error = assert_raises(SeleniumServices::Lexica::LexicaStop) do
      harness.confirm_review_page
    end
    assert_equal "purchase_blocked", error.error_kind
    assert_equal 1, harness.upsell_calls
    assert_equal true, harness.confirm_teiki_applied
    assert_empty harness.clicks
  end

  def test_confirm_already_on_confirm_applies_teiki_once
    harness = Harness.new(
      urls: [
        "https://cart.example.test/order/confirm",
        "https://cart.example.test/order/complete?code=1"
      ]
    )
    harness.click_confirm_teiki = true
    harness.confirm_review_page

    assert_equal 1, harness.upsell_calls
    assert_equal [["button.btn-submit-checkout", "confirm order"]], harness.clicks
    assert_equal "_P046", harness.selenium_result.resolved_sku
    assert_includes JSON.parse(harness.selenium_result.offer_surfaces), "confirm_upsell"
  end

  def test_teiki_with_flag_off_raises_disabled
    harness = Harness.new(
      urls: ["https://cart.example.test/order/confirm"],
      offer_flag: false
    )
    harness.click_confirm_teiki = true

    error = assert_raises(SeleniumServices::Lexica::LexicaStop) do
      harness.confirm_review_page
    end
    assert_equal "confirm_upsell_disabled", error.error_kind
    assert_empty harness.clicks
  end

  def test_no_teiki_when_upsell_not_selected
    harness = Harness.new(
      urls: [
        "https://cart.example.test/order/confirm",
        "https://cart.example.test/order/complete?code=1"
      ]
    )
    harness.click_confirm_teiki = false
    harness.confirm_review_page

    assert_equal 1, harness.upsell_calls
    assert_equal false, harness.confirm_teiki_applied
    assert_equal [["button.btn-submit-checkout", "confirm order"]], harness.clicks
  end
end
