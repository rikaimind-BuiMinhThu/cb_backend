module SubscStore
  class Catalog
    def initialize(http_client)
      @http = http_client
    end

    def as_json
      {
        "products" => products,
        "regular_courses" => regular_courses,
        "distribution_courses" => distribution_courses,
        "frequencies" => frequencies
      }
    end

    def products
      @products ||= serialize_products(fetch_list("/products", "products"))
    end

    def regular_courses
      @regular_courses ||= serialize_courses(fetch_list("/regular_courses", "regular_courses"))
    end

    def distribution_courses
      @distribution_courses ||= serialize_courses(fetch_list("/distribution_courses", "distribution_courses"))
    end

    def frequencies
      @frequencies ||= serialize_simple_items(fetch_list("/frequencies", "frequencies", optional: true))
    end

    private

    def fetch_list(path, key, optional: false)
      extract_list(@http.get(path), key)
    rescue Error
      raise unless optional

      []
    end

    def extract_list(result, key)
      return [] if result.blank?
      return result if result.is_a?(Array)

      hash = indifferent(result)
      array_wrap(hash[key] || hash["data"] || hash["items"])
    end

    def serialize_products(items)
      array_wrap(items).map { |item| serialize_product(item) }.compact
    end

    def serialize_courses(items)
      array_wrap(items).map { |item| serialize_course(item) }.compact
    end

    def serialize_product(item)
      hash = indifferent(item)
      id = hash["id"] || hash[:id]
      return nil if id.blank?

      {
        "id" => id,
        "name" => item_name(hash, id),
        "variants" => serialize_simple_items(
          hash["variants"] || hash["product_variants"] || hash["product_variant"]
        )
      }
    end

    def serialize_course(item)
      hash = indifferent(item)
      id = hash["id"] || hash[:id]
      return nil if id.blank?

      nested_products = hash["products"] || hash["merchandises"] || hash["course_products"]
      {
        "id" => id,
        "name" => item_name(hash, id),
        "products" => serialize_products(nested_products),
        "frequencies" => serialize_simple_items(hash["frequencies"] || hash["frequency"])
      }
    end

    def serialize_simple_items(items)
      array_wrap(items).map do |item|
        hash = indifferent(item)
        id = hash["id"] || hash[:id]
        next if id.blank?

        { "id" => id, "name" => item_name(hash, id) }
      end.compact
    end

    def item_name(hash, id)
      hash["name"].presence || hash["title"].presence || hash["label"].presence || id.to_s
    end

    def array_wrap(value)
      return [] if value.blank?
      return value if value.is_a?(Array)

      [value]
    end

    def indifferent(item)
      return {}.with_indifferent_access if item.blank?
      return item.with_indifferent_access if item.respond_to?(:with_indifferent_access)

      { "name" => item }.with_indifferent_access
    end
  end
end
