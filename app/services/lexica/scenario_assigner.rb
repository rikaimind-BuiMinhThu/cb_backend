module Lexica
  class ScenarioAssigner
    ORDER_RESULT_MODES = %w[wait async].freeze
    DEFAULT_ORDER_RESULT_MODE = "wait"
    OFFER_FLAGS = {
      lexica_offer_chat: true,
      lexica_offer_confirm_upsell: true,
      lexica_offer_confirm_cross_sell: false,
      lexica_offer_thanks_upsell: true,
      lexica_offer_thanks_cross_sell: true
    }.freeze

    def self.call(scenario:, client:, params:)
      new(scenario: scenario, client: client, params: params).call
    end

    def initialize(scenario:, client:, params:)
      @scenario = scenario
      @client = client
      @params = params
    end

    def call
      return unless @client&.lexica?

      @scenario.merchandise_id = @params[:merchandise_id].to_s.strip.presence
      @scenario.lexica_cart_url = @params[:lexica_cart_url]
      mode = @params[:order_result_mode].to_s
      @scenario.order_result_mode = ORDER_RESULT_MODES.include?(mode) ? mode : DEFAULT_ORDER_RESULT_MODE
      assign_offers!
    end

    private

    def assign_offers!
      if @params.key?(:lexica_upsell_product_url)
        @scenario.lexica_upsell_product_url = @params[:lexica_upsell_product_url]
      end
      @scenario.lexica_upsell_sku = @params[:lexica_upsell_sku]
      if @params.key?(:lexica_cross_sell_product_url)
        @scenario.lexica_cross_sell_product_url = @params[:lexica_cross_sell_product_url]
      end
      @scenario.lexica_cross_sell_sku = @params[:lexica_cross_sell_sku]

      bool = ActiveModel::Type::Boolean.new
      OFFER_FLAGS.each do |name, default|
        assign_flag(name, bool, default)
      end
    end

    def assign_flag(name, caster, default)
      return unless @scenario.respond_to?("#{name}=")

      if @params.key?(name)
        @scenario.public_send("#{name}=", caster.cast(@params[name]))
      elsif @scenario.public_send(name).nil?
        @scenario.public_send("#{name}=", default)
      end
    end
  end
end
