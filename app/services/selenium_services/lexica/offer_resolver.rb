module SeleniumServices
  module Lexica
    class OfferResolver
      DECLINE_VALUES = %w[not_upsell not_cross_sell 0 false].freeze

      Result = Struct.new(
        :sku,
        :product_url,
        :cart_skus,
        :surfaces,
        :cross_sell_sku,
        :cross_sell_url,
        keyword_init: true
      )

      def initialize(scenario, conversations)
        @scenario = scenario
        @conversations = Array(conversations)
      end

      def resolve!
        sku = @scenario.merchandise_id.to_s
        product_url = @scenario.landing_page_product_url.to_s
        surfaces = []
        cross_sell_sku = nil
        cross_sell_url = nil

        if selected?("upsell")
          raise_missing!("missing_upsell_product", "アップセル商品URLまたは商品コードが未設定です") if upsell_incomplete?
          sku = @scenario.lexica_upsell_sku.to_s
          product_url = @scenario.lexica_upsell_product_url.to_s
          surfaces << "chat_upsell"
        end

        cart_skus = [sku].reject(&:blank?)

        if selected?("cross_sell")
          raise_missing!("missing_cross_sell_product", "クロスセル商品URLまたは商品コードが未設定です") if cross_sell_incomplete?
          cross_sell_sku = @scenario.lexica_cross_sell_sku.to_s
          cross_sell_url = @scenario.lexica_cross_sell_product_url.to_s
          cart_skus << cross_sell_sku unless cart_skus.include?(cross_sell_sku)
          surfaces << "chat_cross_sell"
        end

        Result.new(
          sku: sku,
          product_url: product_url,
          cart_skus: cart_skus,
          surfaces: surfaces,
          cross_sell_sku: cross_sell_sku,
          cross_sell_url: cross_sell_url
        )
      end

      private

      def selected?(name)
        raw = conversation_value(name)
        return false if raw.blank?

        !DECLINE_VALUES.include?(raw.to_s.strip.downcase)
      end

      def conversation_value(name)
        row = @conversations.detect { |item| item.data_input_name.to_s == name }
        row&.value
      end

      def upsell_incomplete?
        @scenario.lexica_upsell_sku.to_s.blank? || @scenario.lexica_upsell_product_url.to_s.blank?
      end

      def cross_sell_incomplete?
        @scenario.lexica_cross_sell_sku.to_s.blank? || @scenario.lexica_cross_sell_product_url.to_s.blank?
      end

      def raise_missing!(kind, message)
        raise OfferError.new(kind, message)
      end
    end

    class OfferError < StandardError
      attr_reader :error_kind

      def initialize(error_kind, message)
        @error_kind = error_kind
        super(message)
      end
    end
  end
end
