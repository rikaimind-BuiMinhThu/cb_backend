require "test_helper"
require "ostruct"

class LexicaOfferResolverTest < ActiveSupport::TestCase
  def setup
    @scenario = OpenStruct.new(
      merchandise_id: "SAMPLE-SKU",
      landing_page_product_url: "https://lp.example.test/10ml",
      lexica_upsell_sku: "SAMPLE-UPSELL-SKU",
      lexica_upsell_product_url: "https://shop.example.test/30ml",
      lexica_cross_sell_sku: "SAMPLE-XSELL-SKU",
      lexica_cross_sell_product_url: "https://shop.example.test/xsell"
    )
  end

  def test_keeps_base_sku_when_upsell_declined
    resolved = resolve!(row("upsell", "not_upsell"))
    assert_equal "SAMPLE-SKU", resolved.sku
    assert_equal ["SAMPLE-SKU"], resolved.cart_skus
    assert_empty resolved.surfaces
  end

  def test_switches_to_upsell_when_up1_selected
    resolved = resolve!(row("upsell", "up1"))
    assert_equal "SAMPLE-UPSELL-SKU", resolved.sku
    assert_equal "https://shop.example.test/30ml", resolved.product_url
    assert_equal ["SAMPLE-UPSELL-SKU"], resolved.cart_skus
    assert_includes resolved.surfaces, "chat_upsell"
  end

  def test_appends_cross_sell_when_xs1_selected
    resolved = resolve!(row("cross_sell", "xs1"))
    assert_equal ["SAMPLE-SKU", "SAMPLE-XSELL-SKU"], resolved.cart_skus
    assert_includes resolved.surfaces, "chat_cross_sell"
  end

  def test_missing_upsell_product_when_up1_and_sku_blank
    @scenario.lexica_upsell_sku = ""
    error = assert_raises(SeleniumServices::Lexica::OfferError) do
      resolve!(row("upsell", "up1"))
    end
    assert_equal "missing_upsell_product", error.error_kind
  end

  def test_raises_when_cross_sell_selected_and_url_blank
    @scenario.lexica_cross_sell_product_url = ""
    error = assert_raises(SeleniumServices::Lexica::OfferError) do
      resolve!(row("cross_sell", "xs1"))
    end
    assert_equal "missing_cross_sell_product", error.error_kind
  end

  private

  def row(name, value)
    OpenStruct.new(data_input_name: name, value: value)
  end

  def resolve!(*conversations)
    SeleniumServices::Lexica::OfferResolver.new(@scenario, conversations).resolve!
  end
end
