module SubscStore
  class OrderChange
    def initialize(client)
      @http = HttpClient.new(client)
    end

    def confirm_and_execute(order_id, payload)
      path = "/orders/#{order_id}/change_order_items"
      confirm = @http.put(path, payload)
      result = @http.post(path, payload)
      { confirm: confirm, result: result }
    end

    def build_payload(scenario, quantity: 1)
      config = scenario.subsc_store_config.with_indifferent_access
      upsell = (config[:upsell] || {}).with_indifferent_access
      raise Error, "Upsell after_item is not configured" if upsell.blank?

      before_kind = (config[:item_kind].presence || "products").to_s
      after_kind = (upsell[:after_item_kind].presence || "regular_courses").to_s
      {
        order: {
          payment_method_shop_id: int_or_nil(config[:payment_method_shop_id_credit] || config[:payment_method_shop_id_np]),
          frequency_id: int_or_nil(upsell[:after_frequency_id] || config[:frequency_id]),
          before_item: item_hash(
            before_kind,
            merchandise_id: config[:merchandise_id] || scenario.merchandise_id,
            variant_id: config[:variant_id],
            course_id: config[:course_id],
            quantity: quantity
          ),
          after_item: item_hash(
            after_kind,
            merchandise_id: upsell[:after_merchandise_id],
            variant_id: upsell[:after_variant_id],
            course_id: upsell[:after_course_id],
            quantity: quantity
          )
        }.compact
      }
    end

    private

    def item_hash(kind, merchandise_id:, variant_id:, course_id:, quantity:)
      case kind.to_s
      when "regular_courses"
        {
          regular_courses: [
            {
              id: int_or_nil(course_id),
              products: [{ id: int_or_nil(merchandise_id), variant_id: int_or_nil(variant_id), quantity: quantity }.compact]
            }.compact
          ]
        }
      when "distribution_courses"
        { distribution_courses: [{ id: int_or_nil(course_id) }] }
      else
        {
          products: [
            { id: int_or_nil(merchandise_id), variant_id: int_or_nil(variant_id), quantity: quantity }.compact
          ]
        }
      end
    end

    def int_or_nil(value)
      return nil if value.blank?

      value.to_i
    end
  end
end
