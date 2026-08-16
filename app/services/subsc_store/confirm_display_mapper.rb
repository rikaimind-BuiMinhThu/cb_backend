module SubscStore
  class ConfirmDisplayMapper
    CREDIT_PATTERN = /クレジット|credit|zeus|gmo|visa|master|jcb|amex/i
    NP_PATTERN = /np|後払/i

    def initialize(confirm_result:, payload:, scenario:, payment_config: nil)
      @result = (confirm_result || {}).with_indifferent_access
      @order = (@result[:order] || {}).with_indifferent_access
      @payload = (payload || {}).with_indifferent_access
      @scenario = scenario
      @config = scenario.subsc_store_config.with_indifferent_access
      @payment_config = payment_config
    end

    def build
      address = (@order[:client_address] || @payload[:client_address] || {}).with_indifferent_access
      shipment = Array(@order[:shipments]).first || {}
      shipment = shipment.with_indifferent_access if shipment.respond_to?(:with_indifferent_access)
      card = (@order[:credit_card] || @payload.dig(:settlement, :credit_card) || {}).with_indifferent_access

      {
        customer_name: join_name(address[:family_name], address[:first_name]),
        customer_name_kana: join_name(address[:family_name_kana], address[:first_name_kana]),
        email: address[:email],
        tel: address[:tel],
        zip_code: format_zip(address[:zip_code]),
        address: format_address(address),
        product: product_label,
        quantity: quantity_value,
        payment_method: payment_method_label,
        card: card_label(card),
        item_total: yen(item_total_value),
        tax_total: yen(@order[:tax_total]),
        shipping_fee: yen(shipment[:postage]),
        payment_fee: yen(@order[:charge_total]),
        coupon_discount: yen(@order[:coupon_adjustment_total]),
        rank_discount: yen(@order[:rank_discount]),
        adjustment: @order[:adjustment_total].presence,
        total: yen(@order[:total]),
        delivery_date: delivery_date_label(shipment)
      }
    end

    def error_message
      errors = Array(@result[:errors]).map { |item| extract_error_text(item) }.reject(&:blank?)
      errors.join("\n")
    end

    def success?
      @result[:success] != false
    end

    private

    def join_name(*parts)
      parts.map { |part| part.to_s.strip }.reject(&:blank?).join(" ").presence
    end

    def format_zip(zip)
      digits = zip.to_s.gsub(/\D/, "")
      return zip.to_s if digits.blank?
      return "#{digits[0, 3]}-#{digits[3, 4]}" if digits.length >= 7

      digits
    end

    def format_address(address)
      [
        prefecture_name(address[:state_id]),
        address[:city],
        address[:address],
        address[:building_name]
      ].map { |part| part.to_s.strip }.reject(&:blank?).join(" ").presence
    end

    def prefecture_name(state_id)
      return nil if state_id.blank?

      code = state_id.to_s.rjust(2, "0")
      Prefecture.find_by(prefecture_jis_code: code)&.name
    end

    def product_label
      @config[:product_name].presence || "ご注文商品"
    end

    def quantity_value
      items = (@order[:order_items] || {}).with_indifferent_access
      first = Array(items[:products]).first || Array(items[:regular_courses]).first || Array(items[:distribution_courses]).first || {}
      first = first.with_indifferent_access if first.respond_to?(:with_indifferent_access)
      first[:quantity].presence || @payload.dig(:order_items, :products, 0, :quantity) || 1
    end

    def item_total_value
      items = (@order[:order_items] || {}).with_indifferent_access
      totals = []
      %w[products regular_courses distribution_courses].each do |kind|
        Array(items[kind]).each do |item|
          hash = item.respond_to?(:with_indifferent_access) ? item.with_indifferent_access : {}
          totals << hash[:total_includes_tax]
        end
      end
      totals.compact.first || @order[:total]
    end

    def payment_method_label
      name = payment_method_shop_name.to_s
      return "クレジットカード" if credit_card_settlement? || name.match?(CREDIT_PATTERN)
      return "NP後払い" if name.match?(NP_PATTERN) || !credit_card_settlement?

      "クレジットカード"
    end

    def credit_card_settlement?
      @order[:credit_card].present? || @payload.dig(:settlement, :credit_card).present?
    end

    def payment_method_shop_name
      method_id = @order[:payment_method_shop_id] || @payload.dig(:settlement, :payment_method_shop_id)
      return "" if method_id.blank? || @payment_config.blank?

      shop = Array(@payment_config.payment_method_shops).find do |item|
        (item["id"] || item[:id]).to_i == method_id.to_i
      end
      return "" if shop.blank?

      [
        shop["name"],
        shop["payment_method_name"],
        shop.dig("payment_method", "name"),
        shop["label"]
      ].compact.join(" ")
    end

    def card_label(card)
      return nil if card.blank? || card[:masked_card_number].blank?

      brand = card[:brand].to_s
      brand = nil if brand.match?(/zeus|gmo|テモナ/i)
      parts = [brand.to_s.upcase.presence, card[:masked_card_number]]
      expiry = [card[:expire_month], card[:expire_year]].reject(&:blank?).join("/")
      parts << "有効期限 #{expiry}" if expiry.present?
      parts.compact.join(" ")
    end

    def delivery_date_label(shipment)
      date = shipment[:scheduled_delivery_on]
      return "指定なし" if date.blank? || shipment[:is_not_specified]

      date
    end

    def yen(value)
      return nil if value.nil? || value.to_s.strip == ""
      return value.to_s if value.to_s.include?("円")

      number = value.to_s.gsub(/[^\d.-]/, "")
      return nil if number.blank?

      numeric = number.include?(".") ? number.to_f.round : number.to_i
      "#{ActiveSupport::NumberHelper.number_to_delimited(numeric)}円"
    end

    def extract_error_text(item)
      text = if item.is_a?(Hash)
        item["message"] || item[:message]
      else
        item.to_s
      end
      return nil if text.blank?
      return Regexp.last_match(1) if text.to_s =~ /message:\s*[`']([^`']+)[`']/
      return nil if text.to_s.match?(/code:\s*[`']/)

      text.to_s
    end
  end
end
